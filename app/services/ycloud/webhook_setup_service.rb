class Ycloud::WebhookSetupService
  include Rails.application.routes.url_helpers

  pattr_initialize [:inbox!]

  def perform
    # no need to do this at the beginning
  end
end
