json.array! @rags do |rag|
  json.partial! 'api/v1/models/rag', formats: [:json], resource: rag
end
