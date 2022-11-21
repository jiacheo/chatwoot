class Whatsapp::Providers::WhatsappYcloudService < Whatsapp::Providers::BaseService

  
  def send_message(phone_number, message)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info)
    response = HTTParty.post(
      "#{api_base_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        to: phone_number,
        from: whatsapp_channel.phone_number,
        template: template_body_parameters(template_info),
        type: 'template'
      }.to_json
    )

    process_response(response)
  end

  def sync_templates
    header = api_headers
    page_size = 100
    page_no = 1
    templates=[]
    # fetch all template, and filter the APPROVED ones
    success = true
    loop do
      response = HTTParty.get("#{api_base_path}/templates?page=#{page_no}&limit=#{page_size}", headers: header)
      size = 0
      if response.success?
        templates << response['items']
        size = response['items'].size
      else
        success = false
        break
      end
      break if size < page_size
      page_no += 1
    end
    templates = templates.flatten(1)
    templates = templates.select do |tmpl|
      tmpl['status'] == 'APPROVED'
    end
    whatsapp_channel.update(message_templates: templates, message_templates_last_updated: Time.now.utc) if success
  end

  def validate_provider_config?
    response = HTTParty.get("#{api_base_path}/templates", headers: api_headers)
    Rails.logger.info("request ycloud api, response:" + response.inspect.to_s)
    response.success?
  end

  # dont need this
  def media_url(media_id)
    ""
  end

  def api_headers
    { 'X-API-Key' => "#{whatsapp_channel.provider_config['api_key']}", 'Content-Type' => 'application/json' }
  end

  YCLOUD_PHONE_NUMBER_REGEX = Regexp.new('^\+\d{1,15}\z')

  private

  

  def api_base_path
    "https://api.ycloud.com/v2/whatsapp"
  end

  def send_text_message(phone_number, message)
    response = HTTParty.post(
      "#{api_base_path}/messages",
      headers: api_headers,
      body: {
        to: phone_number,
        from: whatsapp_channel.phone_number,
        text: { body: message.content },
        type: 'text'
      }.to_json
    )

    process_response(response)
  end

  def send_attachment_message(phone_number, message)
    
    attachment = message.attachments.first
    type = %w[image audio video].include?(attachment.file_type) ? attachment.file_type : 'document'
    attachment_url = attachment.download_url
    type_content = {
      'link': attachment_url
    }
    type_content['caption'] = message.content if type != 'audio'
    response = HTTParty.post(
      "#{api_base_path}/messages",
      headers: api_headers,
      body: {
        messaging_product: 'whatsapp',
        'to' => phone_number,
        'type' => type,
        'from' => whatsapp_channel.phone_number,
        type.to_s => type_content
      }.to_json
    )

    process_response(response)
  end

  def process_response(response)
    if response.success?
      response['id']
    else
      Rails.logger.error response.body
      nil
    end
  end

  def template_body_parameters(template_info)
    {
      name: template_info[:name],
      language: {        
        code: template_info[:lang_code]
      },
      components: [{
        type: 'body',
        parameters: template_info[:parameters]
      }]
    }
  end
end
