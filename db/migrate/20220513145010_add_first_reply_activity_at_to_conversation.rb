class AddFirstReplyActivityAtToConversation < ActiveRecord::Migration[6.1]
  def change
    add_column :conversations, :first_reply_created_at, :datetime, default: Time.now.utc
    add_index :conversations, :first_reply_created_at

    add_first_reply_activity_at_to_conversations
  end

  private

  def add_first_reply_activity_at_to_conversations
    ::Account.find_in_batches do |account_batch|
      Rails.logger.info "Migrated till #{account_batch.first.id}\n"
      account_batch.each do |account|
        Account::ConversationsFirstReplySchedulerJob.perform_later(account)
      end
    end
  end
end
