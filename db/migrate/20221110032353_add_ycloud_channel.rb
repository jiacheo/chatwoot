class AddYcloudChannel < ActiveRecord::Migration[6.1]
  def change
    create_table :channel_ycloud do |t|
      t.integer :account_id, null: false
      t.string :ycloud_channel_id, null: false, index: { unique: true }
      t.string :ycloud_channel_apikey, null: false
      t.timestamps
    end
  end
end
