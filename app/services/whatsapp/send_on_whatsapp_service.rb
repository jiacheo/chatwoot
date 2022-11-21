class Whatsapp::SendOnWhatsappService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Whatsapp
  end

  def perform_reply
    should_send_template_message = template_params.present? || !message.conversation.can_reply?
    if should_send_template_message
      send_template_message
    else
      send_session_message
    end
  end

  def send_template_message
    name, namespace, lang_code, processed_parameters = processable_channel_message_template

    return if name.blank?

    message_id = channel.send_template(message.conversation.contact_inbox.source_id, {
                                         name: name,
                                         namespace: namespace,
                                         lang_code: lang_code,
                                         parameters: processed_parameters
                                       })
    message.update!(source_id: message_id) if message_id.present?
  end

  def processable_channel_message_template
    if template_params.present?
      #the parameters' order from javascript is not original sorted, must be sorted again here 
      tempalte_name = template_params['name']
      template_lang = template_params['language'];
      template_variables = []
      channel.message_templates&.each do |template|
        if template['name'] == tempalte_name && template['language'] == template_lang
          text = template['components'][0]['text']
          keywords = find_keywords_in_templates(text)
          keywords.each do |word|
            template_variables << template_params['processed_params'][word]
          end
          break
        end
      end
      return [
        template_params['name'],
        template_params['namespace'],
        template_params['language'],
        template_variables.map { |val| {type: 'text', text: template_params['processed_params'][val]} }
      ]
    end
  end

  def find_keywords_in_templates(str)
    word_list = []
    first_match = second_match = third_match = last_match = false
    str.each_char do |ch|
      if ch == '{' && first_match == false
        first_match = true
      elsif ch == '{' && first_match == true
        econd_match = true
      end
      if ch != '{' && first_match && second_match && ch != '}'
        word << ch
      end
      if ch == '}' && third_match == false
        third_match = true
      elsif ch == '}' && third_match = true
        last_match = true
      end
      if third_match && last_match
        word_list << word if word.length > 0
        word = ""
        first_match = false
        second_match = false
        third_match = false
        last_match = false
      end
    end
    word_list
  end

    # Delete the following logic once the update for template_params is stable
    # see if we can match the message content to a template
    # An example template may look like "Your package has been shipped. It will be delivered in {{1}} business days.
    # We want to iterate over these templates with our message body and see if we can fit it to any of the templates
    # Then we use regex to parse the template varibles and convert them into the proper payload
    channel.message_templates&.each do |template|
      match_obj = template_match_object(template)
      next if match_obj.blank?

      # we have a match, now we need to parse the template variables and convert them into the wa recommended format
      processed_parameters = match_obj.captures.map { |x| { type: 'text', text: x } }

      # no need to look up further end the search
      return [template['name'], template['namespace'], template['language'], processed_parameters]
    end
    [nil, nil, nil, nil]
  end

  def template_match_object(template)
    body_object = validated_body_object(template)
    return if body_object.blank?

    template_match_regex = build_template_match_regex(body_object['text'])
    message.content.match(template_match_regex)
  end

  def build_template_match_regex(template_text)
    # Converts the whatsapp template to a comparable regex string to check against the message content
    # the variables are of the format {{num}} ex:{{1}}

    # transform the template text into a regex string
    # we need to replace the {{num}} with matchers that can be used to capture the variables
    template_text = template_text.gsub(/{{\d}}/, '(.*)')
    # escape if there are regex characters in the template text
    template_text = Regexp.escape(template_text)
    # ensuring only the variables remain as capture groups
    template_text = template_text.gsub(Regexp.escape('(.*)'), '(.*)')

    template_match_string = "^#{template_text}$"
    Regexp.new template_match_string
  end

  def validated_body_object(template)
    # we don't care if its not approved template
    return if template['status'] != 'approved'

    # we only care about text body object in template. if not present we discard the template
    # we don't support other forms of templates
    template['components'].find { |obj| obj['type'] == 'BODY' && obj.key?('text') }
  end

  def send_session_message
    message_id = channel.send_message(message.conversation.contact_inbox.source_id, message)
    message.update!(source_id: message_id) if message_id.present?
  end

  def template_params
    message.additional_attributes && message.additional_attributes['template_params']
  end
end
