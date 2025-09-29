# == Schema Information
#
# Table name: calendars
#
#  id            :bigint           not null, primary key
#  access_token  :text             not null
#  email         :string
#  id_token      :text             not null
#  picture       :text
#  platform      :string           not null
#  refresh_token :text             not null
#  user_name     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer          not null
#  agent_bot_id  :integer          not null
#
class Calendar < ApplicationRecord
  belongs_to :account
  belongs_to :agent_bot

  validates :platform, :id_token, :access_token, :refresh_token, :account_id, :agent_bot_id, presence: true
end
