class ChangeCalendarTokensToText < ActiveRecord::Migration[7.0]
  def up
    change_column :calendars, :id_token,      :text
    change_column :calendars, :access_token,  :text
    change_column :calendars, :refresh_token, :text
  end

  def down
    change_column :calendars, :id_token,      :string, limit: 255
    change_column :calendars, :access_token,  :string, limit: 255
    change_column :calendars, :refresh_token, :string, limit: 255
  end
end
