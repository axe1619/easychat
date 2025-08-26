class AddFieldsRemarketingToInboxes < ActiveRecord::Migration[7.0]
  def change
     add_column :inboxes, :behavior_remarketing, :text
     add_column :inboxes, :cout_max_remarketing_message, :integer, default: 0
     add_column :inboxes, :time_wait_last_message, :integer, default: 0
     add_column :inboxes, :unit_time, :integer, default: 0
  end
end
