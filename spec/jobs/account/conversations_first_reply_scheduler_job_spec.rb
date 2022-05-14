require 'rails_helper'

RSpec.describe Account::ConversationsFirstReplySchedulerJob, type: :job do
  subject(:job) { described_class.perform_later }

  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:user) { create(:user, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let!(:message) do
    create(:message, content: 'Hi', message_type: 'outgoing', account: account, inbox: inbox,
                     conversation: conversation)
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('scheduled_jobs')
  end

  it 'updates the conversation first reply with the first outgoing message created time' do
    create(:message, content: 'Hello', message_type: 'outgoing', account: account, inbox: inbox,
                     conversation: conversation)

    described_class.perform_now(account)
    conversation.reload

    expect(conversation.messages.count).to eq 2
    expect(conversation.first_reply_created_at.to_i).to eq message.created_at.to_i
  end
end
