require 'rails_helper'

RSpec.describe Webhooks::YcloudEventsJob, type: :job do
  subject(:job) { described_class.perform_later(params: params) }

  let!(:ycloud_channel) { create(:channel_ycloud) }
  let!(:params) { { ycloud_channel_id: ycloud_channel.ycloud_channel_id, 'ycloud' => { test: 'test' } } }
  let(:post_body) { params.to_json }
  # becare, this very complex
  #let(:signature) { Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), line_channel.line_channel_secret, post_body)) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(params: params)
      .on_queue('default')
  end

  context 'when invalid params' do
    it 'returns nil when no ycloud_channel_id' do
      expect(described_class.perform_now(params: {})).to be_nil
    end

    it 'returns nil when invalid bot_token' do
      expect(described_class.perform_now(params: { 'ycloud_channel_id' => 'invalid_id', 'ycloud' => { test: 'test' } })).to be_nil
    end
  end

  context 'when valid params' do
    it 'calls Ycloud::IncomingMessageService' do
      process_service = double
      allow(Ycloud::IncomingMessageService).to receive(:new).and_return(process_service)
      allow(process_service).to receive(:perform)
      expect(Ycloud::IncomingMessageService).to receive(:new).with(inbox: ycloud_channel.inbox,
                                                                 params: params['ycloud'].with_indifferent_access)
      expect(process_service).to receive(:perform)
      described_class.perform_now(params: params, post_body: post_body, signature: signature)
    end
  end
end
