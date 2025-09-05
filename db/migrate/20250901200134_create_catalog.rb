class CreateCatalog < ActiveRecord::Migration[7.0]
  def change
    create_table :catalogs do |t|
      
      t.string :codigo,	        null:false
      t.string :nombre,	        null:false
      t.string :descripcion,	  null:false

      t.string :descripcion_larga	
      t.string :categoria	
      t.string :subcategoria	
      t.string :precio	
      t.string :moneda	
      t.string :unidad_medida	
      t.string :presentacion	
      t.string :stock_disponible	
      t.string :stock_minimo	
      t.string :descuento	
      t.string :precio_oferta	
      t.string :impuesto	
      t.string :estado	
      t.string :marca	
      t.string :proveedor	
      t.string :codigo_barras	
      t.string :imagen_url	
      t.string :galeria_imagenes	
      t.string :ficha_tecnica_url	
      t.string :manual_url	
      t.string :video_url	
      t.string :pais_origen	
      t.string :garantia	
      t.string :fecha_creacion	
      t.string :fecha_actualizacion	
      t.string :etiquetas	
      t.string :politicas_envio	
      t.string :politicas_devolucion	
      t.string :variantes	
      t.string :relacionados	
      t.string :ratings

      t.timestamps
    end

    # Evita cadenas vacias o espacios
    add_check_constraint :catalogs, "char_length(trim(codigo)) > 0",      name: "catalogs_codigo_not_blank"
    add_check_constraint :catalogs, "char_length(trim(nombre)) > 0",      name: "catalogs_nombre_not_blank"
    add_check_constraint :catalogs, "char_length(trim(descripcion)) > 0", name: "catalogs_descripcion_not_blank"
  end
end
