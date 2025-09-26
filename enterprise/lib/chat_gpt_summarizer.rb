class ChatGptSummarizer
  def self.base_uri
    'https://api.openai.com'
  end

  def initialize
    @model = 'gpt-4o'
  end

  def summarize(messages)
    prompt = <<~PROMPT
      Summarize the following array of messages in a single paragraph:

      #{messages.map.with_index(1) { |m, i| "#{i}. #{m}" }.join("\n")}
    PROMPT

    response = request_gpt(prompt)
    response['choices'][0]['message']['content'].strip
  end

  private

  def request_gpt(prompt)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
    }

    body = {
      model: @model,
      messages: [
        { role: 'system', content: "Eres un asistente que resume mensajes en un párrafo claro y conciso." },
        { role: 'user', content: prompt }
      ]
    }.to_json

    Rails.logger.info "Requesting Chat GPT with body: #{body}"
    response = HTTParty.post(
      "#{self.class.base_uri}/v1/chat/completions",
      headers: headers,
      body: body
    )
    Rails.logger.info "Chat GPT response: #{response.body}"
    JSON.parse(response.body)
  end
end
