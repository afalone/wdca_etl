require_relative 'boot'
require 'json'
require 'nokogiri'

class Prod
  def call
    data = { messages: [] }

    File.open('data/messages.html') do |f|
      text = Nokogiri::HTML(f.read)

      data[:messages] += text.css('.page_body .history .message').each.with_object([]) do |msg, arr|
        arr << extract(msg)
      end
      pp data[:messages].size, data[:messages].last(5), data[:messages].first(5)
    end
  end

  private

  def extract(msg)
    obj = {}
    obj.merge!(extract_date(msg))
    obj[:external_id] = msg.attributes['id']&.value
    obj.merge!(extract_kind(msg, obj))
    return obj.merge(extract_service_body(msg)) if %w(service service-no-id).include?(obj[:kind])

    obj.merge!(extract_body(msg))
    # from_name
    # forwarded_from
    # userpic
    # reply_to

    obj
  end

  def extract_date(msg)
    date = msg.css('.date.details').first
    return {} if date.nil?

    { published_short: date.content, published: date.attributes['title'].value }
  end

  def extract_kind(msg, obj)
    classes = msg['class']&.split || []
    return { kind: 'default' } unless classes.include?('service')

    return { kind: 'service' } if obj[:external_id]

    { kind: 'service-no-id' }
  end

  def extract_service_body(msg)
    body = msg.css('.body.details').first
    return {} unless body

    { content: body.content.strip }
  end

  def extract_body(msg)
    {}
  end
end

Prod.new.call
