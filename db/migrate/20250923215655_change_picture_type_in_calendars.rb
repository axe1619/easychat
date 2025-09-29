class ChangePictureTypeInCalendars < ActiveRecord::Migration[7.0]
  def up
    change_column :calendars, :picture, :text
  end

  def down
    change_column :calendars, :picture, :string
  end
end
