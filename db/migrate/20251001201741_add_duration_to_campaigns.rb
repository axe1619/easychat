class AddDurationToCampaigns < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :duration, :integer
  end
end
