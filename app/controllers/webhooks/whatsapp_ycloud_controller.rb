class Webhooks::WhatsappYcloudController < ActionController::API

  def process_payload
    Webhooks::YcloudEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private
  
end
