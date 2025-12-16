# TODO: logic is written tailored to contact import since its the only import available
# let's break this logic and clean this up in future

class DataImportJob < ApplicationJob
  queue_as :low
  retry_on ActiveStorage::FileNotFoundError, wait: 1.minute, attempts: 3

  def perform(data_import)
    @data_import = data_import
    @contact_manager = DataImport::ContactManager.new(@data_import.account)
    @labels = @data_import.account.labels
    begin
      process_import_file
      send_import_notification_to_admin
    rescue CSV::MalformedCSVError => e
      handle_csv_error(e)
    end
  end

  private

  def process_import_file
    @data_import.update!(status: :processing)
    contacts, rejected_contacts = parse_csv_and_build_contacts

    import_contacts(contacts)
    update_data_import_status(contacts.length, rejected_contacts.length)
    save_failed_records_csv(rejected_contacts)
  end

  def parse_csv_and_build_contacts
    contacts = []
    rejected_contacts = []
    # Ensuring that importing non utf-8 characters will not throw error
    data = @data_import.import_file.download
    utf8_data = data.force_encoding('UTF-8')

    # Ensure that the data is valid UTF-8, preserving valid characters
    clean_data = utf8_data.valid_encoding? ? utf8_data : utf8_data.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8')
    separator = clean_data.include?(';') ? ';' : ','
    csv = CSV.parse(clean_data, headers: true, col_sep: separator)
    allowed_tags = @labels.pluck(:title)

    csv.each do |row|
      current_contact = @contact_manager.build_contact(row.to_h.with_indifferent_access)
      if row['labels'].present?
        current_contact.label_list = row['labels'].split(/[;,]/).map(&:strip) & allowed_tags
      end

      if current_contact.valid?
        contacts << current_contact
      else
        append_rejected_contact(row, current_contact, rejected_contacts)
      end
    end

    [contacts, rejected_contacts]
  end

  def append_rejected_contact(row, contact, rejected_contacts)
    row['errors'] = contact.errors.full_messages.join(', ')
    rejected_contacts << row
  end

  def import_contacts(contacts)          
    # <struct ActiveRecord::Import::Result failed_instances=[], num_inserts=1, ids=[444, 445], results=[]>
    Contact.import(contacts, synchronize: contacts, on_duplicate_key_ignore: true, track_validation_failures: true, validate: true, batch_size: 1000)
    run_trigger_taggings_contact(contacts)
  end

  def run_trigger_taggings_contact(contacts)
    contacts.each do |contact|
      next if contact.label_list.blank?

      contact_saved = Contact.find_by(id: contact.id)
      next unless contact_saved
      
      contact_saved.label_list = contact.label_list
      contact_saved.save_tags
    end
  end

  def update_data_import_status(processed_records, rejected_records)
    @data_import.update!(status: :completed, processed_records: processed_records, total_records: processed_records + rejected_records)
  end

  def save_failed_records_csv(rejected_contacts)
    csv_data = generate_csv_data(rejected_contacts)
    return if csv_data.blank?

    @data_import.failed_records.attach(io: StringIO.new(csv_data), filename: "#{Time.zone.today.strftime('%Y%m%d')}_contacts.csv",
                                       content_type: 'text/csv')
    send_import_notification_to_admin
  end

  def generate_csv_data(rejected_contacts)
    headers = CSV.parse(@data_import.import_file.download, headers: true).headers
    headers << 'errors'
    return if rejected_contacts.blank?

    CSV.generate do |csv|
      csv << headers
      rejected_contacts.each do |record|
        csv << record
      end
    end
  end

  def handle_csv_error(error) # rubocop:disable Lint/UnusedMethodArgument
    @data_import.update!(status: :failed)
    send_import_failed_notification_to_admin
  end

  def send_import_notification_to_admin
    AdministratorNotifications::ChannelNotificationsMailer.with(account: @data_import.account).contact_import_complete(@data_import).deliver_later
  end

  def send_import_failed_notification_to_admin
    AdministratorNotifications::ChannelNotificationsMailer.with(account: @data_import.account).contact_import_failed.deliver_later
  end
end
