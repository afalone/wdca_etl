require_relative 'boot'
require 'json'
require 'nokogiri'

LIST = [''] + %w(2 3 4 5 6 7 8 9 10 11 12 13 14 15)

class Prod
  def call
    data = { messages: [] }

    LIST.each { |num| process_file(data, "data/messages#{num}.html") }

    pp data[:messages].size, data[:messages].last(5), data[:messages].first(10)
  end

  private

  def process_file(data, name)
    return unless File.exist?(name)

    File.open(name) do |f|
      text = Nokogiri::HTML(f.read)

      data[:messages] += text.css('.page_body .history .message').each.with_object([]) do |msg, arr|
        arr << extract(msg)
      end
    end
  end

  def extract(msg)
    obj = {}
    obj.merge!(extract_joined(msg))
    obj[:external_id] = msg.attributes['id']&.value
    obj.merge!(extract_kind(msg, obj))
    return obj.merge(extract_service_body(msg)) if %w(service service-no-id).include?(obj[:kind])

    obj.merge!(extract_userpic(msg)) unless obj[:joined]
    extract_body(msg, obj)

    obj
  end

  def extract_joined(msg)
    classes = msg['class']&.split || []
    return { joined: true } if classes.include?('joined')

    { joined: false }
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

    { text: body.content.strip }
  end

  def extract_userpic(msg)
    pic = msg.css('.userpic_wrap .userpic').first
    # TODO:
    # pp pic.attributes['src']&.value if pic
    # pp msg.to_html unless pic && pic.attributes['src']
    {}
  end

  def extract_body(msg, obj)
    # from_name
    # forwarded_from
    body = msg.css('.body').first
    unless obj[:joined]
      obj.merge!(extract_date(body))
      obj.merge!(extract_from(body))
      obj.merge!(extract_forwarded(body))
      obj.merge!(extract_reply(body))
    end
    obj.merge!(extract_content(body))
  end

  def extract_date(body)
    date = body.css('.date.details').first
    return {} if date.nil?

    { published_short: date.content, published: date.attributes['title'].value }
  end

  def extract_from(body)
    from = body.css('.from_name').first
    return {} if from.nil?

    { from_name: from.content.strip }
  end

  def extract_forwarded(body)
    fwd = body.css('.forwarded_from').first
    return {} if fwd.nil?

    { forwarded_from: fwd.content.strip }
  end

  def extract_reply(body)
    a = body.css('.reply_to a').first
    return {} if a.nil?

    ref = a.attributes['href']&.value
    return {} if ref.nil?

    { reply_to: ref.delete_prefix('#go_to_') }
  end

  def extract_content(body)
    txt = body.css('.text').first
    return {} if txt.nil?

    { text: txt.inner_html.strip }
  end
end

Prod.new.call
