class Api::V1::Accounts::Channels::YcloudChannelsController < Api::V1::Accounts::BaseController
  before_action :authorize_request

  def create
    ActiveRecord::Base.transaction do
      authenticate_ycloud
      build_inbox
      #setup_webhooks
    rescue StandardError => e
      render_could_not_create_error(e.message)
    end
  end

  private

  def authorize_request
    authorize ::Inbox
  end

  def authenticate_ycloud
    YCloudApiClient.configure do |config|
      config.api_key['api_key'] = permitted_params['apikey']
    end
    api_instance = YCloudApiClient::BalanceApi.new
    api_instance.balance_retrieve
    #see what the permitted_params.
    permitted_params
  end

  def setup_webhooks
    ::Ycloud::WebhookSetupService.new(inbox: @inbox).perform
  end


  def build_inbox
    @ycloud_channel = Current.account.ycloud.create!(
      ycloud_channel_apikey: permitted_params[:apikey]      
    )
    @inbox = Current.account.inboxes.create!(
      name: permitted_params[:name],
      channel: @ycloud_channel
    )
  end

  def permitted_params
    params.require(:ycloud_channel).permit(
      :account_id, :ycloud_channel_id,  :ycloud_channel_apikey, :name
    )
  end
end
