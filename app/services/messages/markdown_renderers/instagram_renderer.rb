class Messages::MarkdownRenderers::InstagramRenderer < Messages::MarkdownRenderers::BaseRenderer
  def render_in_reply_to
    data = render_in_reply_to_data
    return if data.blank?

    render_template('partials/in_reply_to', data)
  end

  def attachment
    render_attachment(@attachment)
  end

  private

  def render_in_reply_to_data
    return {} if @message.content_attributes.blank?

    story_id = @message.content_attributes['story_id']
    return {} unless story_id.present?

    story_sender = story_id['from']
    story_sent_at = story_id['created_at']

    story = {
      href: "https://www.instagram.com/stories/direct/#{story_sender}_#{story_id['id']}",
      content: I18n.t('conversations.messages.instagram_story_reply_content', story_sender: story_sender)
    }

    { story: story, story_sent_at: story_sent_at }
  end
end
