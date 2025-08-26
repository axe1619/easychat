class AddSubTypeToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :message_sub_type, :integer, null: false, default: 0
  end
end   
