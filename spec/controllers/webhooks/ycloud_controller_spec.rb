require 'rails_helper'

RSpec.describe 'Webhooks::YcloudController', type: :request do
  describe 'POST /webhooks/ycloud/{:ycloud_channel_id}' do
    it 'call the ycloud events job with the params' do
      allow(Webhooks::YcloudEventsJob).to receive(:perform_later)
      expect(Webhooks::YcloudEventsJob).to receive(:perform_later)
      post '/webhooks/ycloud/ycloud_channel_id', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end
  end
end
