class Webhooks::YcloudEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    
    if params[:type] == 'whatsapp.inbound_message.received'
      if params[:whatsappInboundMessage]
        phone_number = params[:whatsappInboundMessage][:to]
        Rails.logger.info("-------receive ycloud event------- phone number is" + phone_number)
        channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
        Rails.logger.info("-------receive ycloud event------- channel is " + (channel?channel.inspect.to_s:"null"))
        return if channel.blank?
        Rails.logger.info("found channel:" + channel.inspect.to_s + ", now do inbox saving")
        #todo: verify the incoming message with channel webhook_token
        Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: transform_params(params)).perform
      end
    end
  end

  ## transform the ycloud params to the base params, so we can reuse the perform codes.
  def transform_params(params = {})
    new_params = {}
    new_params[:messages] = [params[:whatsappInboundMessage]]
    new_params
  end

  private

  def find_channel(params)
    return unless params[:phone_number]

    Channel::Whatsapp.find_by(phone_number: params[:phone_number])
  end

end
