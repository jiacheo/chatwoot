class Webhooks::YcloudEventsJob < ApplicationJob
  queue_as :default


  def perform(params = {})
    Rails.logger.info("ycloud_event_triggered, params:" + params.inspect)
    if params[:type] == 'whatsapp.inbound_message.received'
      if params[:whatsappInboundMessage]
        phone_number = params[:whatsappInboundMessage][:to]
        channel = Channel::Whatsapp.find_by(phone_number: phone_number)
        # channel = Channel::Whatsapp.find(1) this dosen't work, why the fuck?
        return if channel.blank?
        #todo: verify the incoming message with channel webhook_token
        Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: transform_params(params)).perform
      end
    end
  end

  private

  ## transform the ycloud params to the base params, so we can reuse the perform codes.
  def transform_params(params = {})
    new_params = {}
    new_params[:messages] = [params[:whatsappInboundMessage]]
    new_params
  end

end
