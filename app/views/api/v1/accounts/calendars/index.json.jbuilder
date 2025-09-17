json.array! @calendars do |item|
  json.partial! 'api/v1/models/calendar', formats: [:json], resource:  item
end
