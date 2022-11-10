class Ycloud::IncomingMessageService
  include ::FileTypeHelper

  pattr_initialize [:params!]

  def perform
    return if ycloud_channel.blank?

    set_contact
    set_conversation
    @message = @conversation.messages.create!(
      content: params[:text],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: params[:id]
    )
    attach_files
  end

  private

  ##becareful about the params variable, it come from the web request, may be not a key=value style (json obj), we must convert it to ease of use.

  def ycloud_channel
    @ycloud_channel ||= ::Channel::Ycloud.find_by(ycloud_channel_id: params[:ycloud_channel_id]) if params[:ycloud_channel_id].present?
    if params[:to].present?
      @ycloud_channel ||= ::Channel::Ycloud.find_by!(ycloud_channel_id: params[:ycloud_channel_id], phone_number: params[:to])
    end
    @ycloud_channel
  end

  def inbox
    @inbox ||= ycloud_channel.inbox
  end

  def account
    @account ||= inbox.account
  end

  def phone_number
    params[:from]
  end

  def formatted_phone_number
    TelephoneNumber.parse(phone_number).international_number
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: params[:From],
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: additional_attributes
    }
  end

  def set_conversation
    @conversation = @contact_inbox.conversations.first
    return if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  def contact_attributes
    {
      name: formatted_phone_number,
      phone_number: phone_number,
      additional_attributes: additional_attributes
    }
  end

  def additional_attributes
    {}
  end


  def attach_files
    return if params[:MediaUrl0].blank?

    attachment_file = Down.download(
      params[:MediaUrl0]
    )

    attachment = @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_type(params[:MediaContentType0])
    )

    attachment.file.attach(
      io: attachment_file,
      filename: attachment_file.original_filename,
      content_type: attachment_file.content_type
    )

    @message.save!
  end
end
