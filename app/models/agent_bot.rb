# == Schema Information
#
# Table name: agent_bots
#
#  id           :bigint           not null, primary key
#  agent_type   :integer          default("general")
#  bot_config   :jsonb
#  bot_type     :integer          default("webhook")
#  description  :string
#  finish_at    :string           default("")
#  init_at      :string           default("")
#  name         :string
#  outgoing_url :string
#  prompt       :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint
#
# Indexes
#
#  index_agent_bots_on_account_id  (account_id)
#

class AgentBot < ApplicationRecord
  include AccessTokenable
  include Avatarable

  has_many :agent_bot_inboxes, dependent: :destroy_async
  has_many :inboxes, through: :agent_bot_inboxes
  has_many :messages, as: :sender, dependent: :nullify
  belongs_to :account, optional: true
  enum bot_type: { webhook: 0, csml: 1 }
  enum agent_type: { general: 0, sales: 1 }

  validate :validate_agent_bot_config
  validates :prompt, length: { maximum: 100_000 }, allow_nil: true
  validates :outgoing_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  def available_name
    name
  end

  def push_event_data(inbox = nil)
    {
      id: id,
      name: name,
      avatar_url: avatar_url || inbox&.avatar_url,
      type: 'agent_bot'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      type: 'agent_bot'
    }
  end

  private

  def validate_agent_bot_config
    errors.add(:bot_config, 'Invalid Bot Configuration') unless AgentBots::ValidateBotService.new(agent_bot: self).perform
  end
end
