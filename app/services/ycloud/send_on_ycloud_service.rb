class YcloudChannel::SendOnYCloudService < Base::SendOnChannelService
  private

  def channel_class
    Channel::YcloudChannel
  end

  def perform_reply
    sms_send_request = YCloudApiClient::SmsSendRequest.new(**message_params)
    begin
      ycloud_message = channel.client.sms_send(sms_send_request)
    rescue YCloudApiClient::ApiError => e
      ChatwootExceptionTracker.new(e, user: message.sender, account: message.account).capture_exception
    end
    message.update!(source_id: ycloud_message.sender_id) if ycloud_message
  end

  def message_params
    {
      text: message.content,
      to: contact_inbox.source_id
    }
  end

  def attachments
    message.attachments.map(&:download_url)
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end

  def outgoing_message?
    message.outgoing? || message.template?
  end
end
