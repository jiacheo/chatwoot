# Mostly modeled after the intial implementation of the service based on 360 Dialog
# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
class Whatsapp::IncomingMessageBaseService
  pattr_initialize [:inbox!, :params!]

  def perform
    processed_params
    set_contact
    Rails.logger.info("whatsapp inbound message contact:" + @contact.inspect + ", contact_inbox:" + @contact_inbox.inspect)
    return unless @contact

    set_conversation
    Rails.logger.info("whatsapp inbound message conversation:" + @conversation.inspect)

    return if @processed_params[:messages].blank? || unprocessable_message_type?

    @message = @conversation.messages.build(
      content: message_content(@processed_params[:messages].first),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: @processed_params[:messages].first[:id].to_s
    )
    Rails.logger.info("whatsapp inbound message message:" + @message.inspect)
    attach_files
    Rails.logger.info("whatsapp inbound message attached_files?:" + @message.inspect)
    res = @message.save!
    Rails.logger.info("whatsapp inbound message message_saved?:" + @message.inspect + ", res:" + res.inspect)
    res
  end

  private

  def processed_params
    @processed_params ||= params
  end

  def message_content(message)
    # TODO: map interactive messages back to button messages in chatwoot
    message.dig(:text, :body) ||
      message.dig(:button, :text) ||
      message.dig(:interactive, :button_reply, :title) ||
      message.dig(:interactive, :list_reply, :title)
  end

  def account
    @account ||= inbox.account
  end

  def set_contact
    contact_params = @processed_params[:whatsappInboundMessage]
    return if contact_params.blank?

    Rails.logger.info("contact_params:" + contact_params.inspect)

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: contact_params[:wabaId],
      inbox: inbox,
      contact_attributes: { name: contact_params.dig(:customerProfile, :name), phone_number: "#{@processed_params[:messages].first[:from]}" }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.last
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def file_content_type(file_type)
    return :image if %w[image sticker].include?(file_type)
    return :audio if %w[audio voice].include?(file_type)
    return :video if ['video'].include?(file_type)

    :file
  end

  def message_type
    @processed_params[:messages].first[:type]
  end

  def unprocessable_message_type?
    %w[reaction contacts].include?(message_type)
  end

  def attach_files
    return if %w[text button interactive].include?(message_type)

    attachment_payload = @processed_params[:messages].first[message_type.to_sym]
    attachment_file = download_attachment_file(attachment_payload)

    @message.content ||= attachment_payload[:caption]
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_file.original_filename,
        content_type: attachment_file.content_type
      }
    )
  end

  def download_attachment_file(attachment_payload)
    Down.download(inbox.channel.media_url(attachment_payload[:id]), headers: inbox.channel.api_headers)
  end
end
