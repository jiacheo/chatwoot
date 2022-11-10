# == Schema Information
#
# Table name: channel_ycloud
#
#  id                  :bigint           not null, primary key
#  ycloud_channel_apikey :string           not null
#  ycloud_channel_token  :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :integer          not null
#  ycloud_channel_id     :string           not null
#
# Indexes
#
#  index_channel_ycloud_on_ycloud_channel_id  (ycloud_channel_id) UNIQUE
#

class Channel::YcloudChannel < ApplicationRecord
  include Channelable

  self.table_name = 'channel_ycloud'
  EDITABLE_ATTRS = [:ycloud_channel_id, :ycloud_channel_apikey].freeze

  validates :ycloud_channel_id, uniqueness: true, presence: true
  validates :ycloud_channel_apikey, presence: true

  def name
    'YCLOUD'
  end

  def client
    YCloudApiClient.configure do |config|
      config.api_key['api_key'] = ycloud_channel_apikey
    end
    @client = YCloudApiClient::SMSApi.new
  end
end
