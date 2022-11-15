class Webhooks::YcloudEventsJob < ApplicationJob
  queue_as :default


  def perform(params = {})
    if params[:type] == 'whatsapp.inbound_message.received'
      if params[:whatsappInboundMessage]
        phone_number = params[:whatsappInboundMessage][:to]
        channel = Channel::Whatsapp.find_by(phone_number: phone_number)
        # channel = Channel::Whatsapp.find(1) this dosen't work, why the fuck?
        return if channel.blank?
        #todo: verify the incoming message with channel webhook_token
        transform_params!(params)
        Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
      end
    end
  end

  private

  ## transform the ycloud params to the base params, so we can reuse the perform codes.
  def transform_params!(params = {})
    params[:messages] = [params[:whatsappInboundMessage]]
  end

end
