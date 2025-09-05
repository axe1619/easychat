class Catalog < ApplicationRecord

  belongs_to :account
  belongs_to :agent_bot

  validates :codigo, :nombre, :descripcion, :account_id, :agent_bot_id, presence: true
end
