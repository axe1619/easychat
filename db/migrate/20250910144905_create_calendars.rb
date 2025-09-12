class CreateCalendars < ActiveRecord::Migration[7.0]
  def change
    create_table :calendars do |t|

      t.string :platform,	          null:false
      t.string :id_token,	          null:false
      t.string :access_token,       null:false
      t.string :refresh_token,      null:false
      t.integer :account_id,        null:false
      t.integer :agent_bot_id,      null:false
      t.string :email
      t.string :user_name
      t.string :picture

      t.timestamps
    end
  end
end
