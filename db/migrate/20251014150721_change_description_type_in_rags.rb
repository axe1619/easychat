class ChangeDescriptionTypeInRags < ActiveRecord::Migration[7.0]
  def up
    change_column :rags, :description, :text
  end

  def down
    change_column :rags, :description, :string
  end
end
