require 'rails_helper'

describe Ycloud::IncomingMessageService do
  let!(:ycloud_channel) { create(:channel_ycloud) }
  let(:params) do
    {
      "id": "evt_djeIQXaQPQyUcRFi",
      "type": "whatsapp.inbound_message.received",
      "apiVersion": "v2",
      "createTime": "2022-03-01T12:00:00.000Z",
      "whatsappInboundMessage":  {
        "id": "wim123456",
        "from": "+447901614024",
        "to": "+447901614024",
        "sendTime": "2022-03-01T12:00:00.000Z",
        "type": "text",
        "text": {
          "body": "Hi there!"
        }
      }
    }.with_indifferent_access
  end  
end
