class Webhooks::YcloudEventsJob < ApplicationJob
  queue_as :default

  def perform(params: {}, signature: '', post_body: '')
    @params = params
    return unless valid_event_payload?
    return unless valid_post_body?(post_body, signature)

    YcloudChannel::IncomingMessageService.new(inbox: @channel.inbox, params: @params['ycloud'].with_indifferent_access).perform
  end

  private

  def valid_event_payload?
    @channel = Channel::YcloudChannel.find_by(ycloud_channel_id: @params[:ycloud_channel_id]) if @params[:ycloud_channel_id]
  end

  # https://ycloud.readme.io/reference/configure-webhooks
  # validate the ycloud payload
  def valid_post_body?(post_body, signature)
    #t = signature.split(",")[0].split("=")[1]
    #sign = signature.split(",")[1].split("=")[1]
    # first, retrieve the secret of this endpoint by api, and cache it with some expiration policy.
    # second, follow the dev doc to do the signature verification, here, we just skip.
    # hash = OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), @channel.ycloud_channel_apikey, post_body)
    #Base64.strict_encode64(hash) == signature
    true
  end
end
