# == Schema Information
#
# Table name: catalogs
#
#  id                   :bigint           not null, primary key
#  categoria            :string
#  codigo               :string           not null
#  codigo_barras        :string
#  descripcion          :string           not null
#  descripcion_larga    :string
#  descuento            :string
#  estado               :string
#  etiquetas            :string
#  fecha_actualizacion  :string
#  fecha_creacion       :string
#  ficha_tecnica_url    :string
#  galeria_imagenes     :string
#  garantia             :string
#  imagen_url           :string
#  impuesto             :string
#  manual_url           :string
#  marca                :string
#  moneda               :string
#  nombre               :string           not null
#  pais_origen          :string
#  politicas_devolucion :string
#  politicas_envio      :string
#  precio               :string
#  precio_oferta        :string
#  presentacion         :string
#  proveedor            :string
#  ratings              :string
#  relacionados         :string
#  stock_disponible     :string
#  stock_minimo         :string
#  subcategoria         :string
#  unidad_medida        :string
#  variantes            :string
#  video_url            :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  agent_bot_id         :bigint           not null
#
# Indexes
#
#  index_catalogs_on_account_id                   (account_id)
#  index_catalogs_on_account_id_and_agent_bot_id  (account_id,agent_bot_id)
#  index_catalogs_on_agent_bot_id                 (agent_bot_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (agent_bot_id => agent_bots.id)
#
class Catalog < ApplicationRecord

  belongs_to :account
  belongs_to :agent_bot

  validates :codigo, :nombre, :descripcion, :account_id, :agent_bot_id, presence: true
end
