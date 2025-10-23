namespace :storage do
  TIME_UNITS = {
    "hours"  => :hour,
    "days"   => :day,
    "weeks"  => :week,
    "months" => :month
  }.freeze
  desc "Deletes files of messages older than a certain date"
  task :clean_file_store_messages, [:start_time,:end_time] => :environment do |t, args|
    # Example usage:
    # rake "storage:clean_file_store_messages[7.days,10.days]"
    value_start, unit_start = args[:start_time].split(".")
    value_end, unit_end = args[:end_time].split(".")
    unless TIME_UNITS[unit_start] && TIME_UNITS[unit_end]
      Rails.logger.info "⚠️ Unit Invalid use : #{TIME_UNITS.keys.join(", ")}"
      exit 1
    end

    date_start = value_start.to_i.public_send(TIME_UNITS[unit_start]).ago
    date_end = value_end.to_i.public_send(TIME_UNITS[unit_end]).ago

    if date_start < date_end
      Rails.logger.info "⚠️ Invalid range: start_time (#{date_start}) must be greater than or equal to end_time (#{date_end})"
      exit 1
    end
    
    file_deleted = 0
    file_errors  = 0
    Attachment.where("created_at BETWEEN ? AND ?", date_end, date_start).find_each do |attachment|
      blob = attachment.file.blob rescue nil
      next unless blob
      begin
        blob.service.delete(blob.key)
        file_deleted += 1
      rescue => e
        file_errors += 1
      end
    end
    Rails.logger.info "🎉 Files deleted between #{date_end} and #{date_start}: success: #{file_deleted}, errors: #{file_errors}"
  end
end
