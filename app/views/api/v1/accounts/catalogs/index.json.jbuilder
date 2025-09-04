json.array! @catalogs do |item|
  json.partial! 'api/v1/models/catalog', formats: [:json], resource: item
end
