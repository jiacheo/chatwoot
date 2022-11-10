class Webhooks::YcloudController < ActionController::API
  def process_payload
    Webhooks::YcloudEventsJob.perform_later(params: params.to_unsafe_hash, signature: request.headers['YCloud-Signature'], post_body: request.raw_post)
    head :ok
  end
end
