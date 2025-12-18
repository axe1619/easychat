require 'administrate/field/base'

class Enterprise::AccountLimitsField < Administrate::Field::Base
  def to_s
    default_limits = { agents: nil, inboxes: nil, agent_bots: nil }
    merged_limits = default_limits.merge(data.presence || {})
    merged_limits.to_json
  end
end
