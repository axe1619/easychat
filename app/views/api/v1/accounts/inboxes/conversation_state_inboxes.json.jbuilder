json.payload do
  json.array! @conversation_states do |state|
    json.id state.id
    json.name state.name
    json.description state.description
    json.color state.color
  end
end
