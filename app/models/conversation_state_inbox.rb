# == Schema Information
#
# Table name: conversation_state_inboxes
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  conversation_state_id :bigint           not null
#  inbox_id              :bigint           not null
#
# Indexes
#
#  index_conversation_state_inboxes  (inbox_id,conversation_state_id) UNIQUE
#
class ConversationStateInbox < ApplicationRecord
  belongs_to :inbox
  belongs_to :conversation_state
end
