class CreateRag < ActiveRecord::Migration[7.0]
  def change
    create_table :rags do |t|
      t.integer :agent_bot_id
      t.string :date
      t.string :collection_name
      t.string :description

      t.timestamps
    end
  end
end
