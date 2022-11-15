class Webhooks::WhatsappYcloudController < ActionController::API
  include MetaTokenVerifyConcern
  def process_payload
    Webhooks::YcloudEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  def valid_token?
    true
  end

end
