class Channel::Ycloud < ApplicationRecord
  include Channelable
  self.table_name = 'channel_ycloud'
  belongs_to :inbox
end
