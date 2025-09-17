class ChangeLongTextFieldsInCatalogs < ActiveRecord::Migration[7.0]
  def up
    change_column :catalogs, :nombre,               :text
    change_column :catalogs, :descripcion,          :text
    change_column :catalogs, :descripcion_larga,    :text
    change_column :catalogs, :imagen_url,           :text
    change_column :catalogs, :galeria_imagenes,     :text
    change_column :catalogs, :ficha_tecnica_url,    :text
    change_column :catalogs, :manual_url,           :text
    change_column :catalogs, :video_url,            :text
    change_column :catalogs, :politicas_envio,      :text
    change_column :catalogs, :politicas_devolucion, :text
  end

  def down
    change_column :catalogs, :nombre,               :string
    change_column :catalogs, :descripcion,          :string
    change_column :catalogs, :descripcion_larga,    :string
    change_column :catalogs, :imagen_url,           :string
    change_column :catalogs, :galeria_imagenes,     :string
    change_column :catalogs, :ficha_tecnica_url,    :string
    change_column :catalogs, :manual_url,           :string
    change_column :catalogs, :video_url,            :string
    change_column :catalogs, :politicas_envio,      :string
    change_column :catalogs, :politicas_devolucion, :string
  end
end
