class Whatsapp::Providers::WhatsappYcloudService < Whatsapp::Providers::BaseService

  
  def send_message(phone_number, message)
    phone_number = to_ycloud_phone_number(phone_number)
    if message.attachments.present?
      send_attachment_message(phone_number, message)
    else
      send_text_message(phone_number, message)
    end
  end

  def send_template(phone_number, template_info)
    phone_number = to_ycloud_phone_number(phone_number)
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
    response = HTTParty.get("#{api_base_path}/templates", headers: api_headers)
    whatsapp_channel.update(message_templates: response['items'], message_templates_last_updated: Time.now.utc) if response.success?
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

  def to_ycloud_phone_number(phone_number)
    return phone_number if YCLOUD_PHONE_NUMBER_REGEX.match(phone_number)
    contact_inbox = ContactInbox.find_by(source_id: phone_number)
    return phone_number if contact_inbox.blank?
    return contact_inbox.contact.phone_number
  end

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
      Rails.logger.info("what's the response look like? " + response.inspect)
      response[:id]
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
