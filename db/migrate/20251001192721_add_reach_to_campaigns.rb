class AddReachToCampaigns < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :reach, :integer
  end
end
