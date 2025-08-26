class WhatsappInstance
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :instance_name, :string
  attribute :chatwoot_account_id, :string
  attribute :chatwoot_token, :string
  attribute :chatwoot_url, :string
  attribute :chatwoot_sign_msg, :boolean, default: false
  attribute :chatwoot_reopen_conversation, :boolean, default: false
  attribute :chatwoot_conversation_pending, :boolean, default: false
  attribute :sign_delimiter, :string
  attribute :import_contacts, :boolean, default: false
  attribute :import_messages, :boolean, default: false
  attribute :days_limit_import_messages, :integer
  attribute :auto_create, :boolean, default: false
  attribute :webhook_url, :string
  attribute :account_id, :integer

  validates :instance_name, presence: true
  validates :account_id, presence: true
  validates :chatwoot_url, format: URI::regexp(%w[http https]), allow_blank: true
  validates :days_limit_import_messages, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  def normalize!
    self.instance_name = instance_name.strip.downcase if instance_name.present?
  end
end
