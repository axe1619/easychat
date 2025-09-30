namespace :storage do
  TIME_UNITS = {
    "hours"  => :hour,
    "days"   => :day,
    "weeks"  => :week,
    "months" => :month
  }.freeze
  desc "Deletes files of messages older than a certain date"
  task :clean_file_store_messages, [:time] => :environment do |t, args|
    # time: ["1.hours","1.days", "1.weeks", "1.months"],
    value, unit = args[:time].split(".")
    unless TIME_UNITS[unit]
      Rails.logger.info "⚠️ Unit Invalid #{unit} use : #{TIME_UNITS.keys.join(", ")}"
      exit 1
    end
    date = value.to_i.public_send(TIME_UNITS[unit]).ago
    file_deleted = 0
    file_errors  = 0
    Attachment.where("created_at < ? ", date).find_each do |attachment|
      blob = attachment.file.blob rescue nil
      next unless blob
      begin
        blob.service.delete(blob.key)
        file_deleted += 1
      rescue => e
        file_errors += 1
      end
    end
    Rails.logger.info "🎉Files deleted before to #{date} : success: #{file_deleted}, errors: #{file_errors}"
  end
end
