# == Schema Information
#
# Table name: conversation_states
#
#  id           :bigint           not null, primary key
#  color        :string
#  description  :text
#  name         :string
#  notification :jsonb
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer
#
class ConversationState < ApplicationRecord
    validates :name, presence: true, uniqueness: { scope: :account_id }
    validates :description, presence: true
    validates :color, presence: true
    validates :account_id, presence: true
end
