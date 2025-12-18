module Api::V1::AgentBotsHelper
  private

  def agent_bot_limit_reached?
    Current.account.agent_bots.count >= Current.account.usage_limits[:agent_bots]
  end

  def agent_bot_limit_remaining
    [Current.account.usage_limits[:agent_bots] - Current.account.agent_bots.count, 0].max
  end

  def validate_limit
    return unless agent_bot_limit_reached?

    render_payment_required('Account limit exceeded. Upgrade to a higher plan')
  end
end
