# == Schema Information
#
# Table name: rags
#
#  id              :bigint           not null, primary key
#  collection_name :string
#  date            :string
#  description     :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer
#  agent_bot_id    :integer
#
class Rag < ApplicationRecord
  belongs_to :account
  belongs_to :agent_bot

  validates :agent_bot_id, :date, :collection_name, :account_id, presence: true
end
