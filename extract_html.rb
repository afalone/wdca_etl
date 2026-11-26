require_relative 'boot'
require 'json'
require 'nokogiri'

LIST = [''] + %w(2 3 4 5 6 7 8 9 10 11 12 13 14 15)

class Prod
  def call
    data = { messages: [] }

    LIST.each { |num| process_file(data, "data/messages#{num}.html") }

    pp data[:messages].size, data[:messages].last(5), data[:messages].first(10)
    js = JSON.generate(data)
    File.open('data/messages.json', 'w') { |f| f.write(js) }
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
    return {} if pic.nil?

    ph = pic.attributes['src']&.value
    return { userpic: ph } if ph

    color = (pic.classes - ['userpic']).first
    initials = pic.css('.initials').first
    { userpic_color: color, userpic_initials: initials.content.strip }
  end

  def extract_body(msg, obj)
    body = msg.css('.body').first
    unless obj[:joined]
      obj.merge!(extract_date(body))
      obj.merge!(extract_from(body))
      obj.merge!(extract_forwarded(body))
      obj.merge!(extract_reply(body))
    end
    obj.merge!(extract_content(body))
    obj.merge!(extract_photo(body))
    # TODO:
    # class="media_wrap clearfix"
    # class="sticker_wrap clearfix pull_left"
    # class="video_file_wrap clearfix pull_left round"
    # class="video_file_wrap clearfix pull_left"
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

  def extract_photo(body)
    img = body.css('a.photo_wrap > img.photo').first
    return {} if img.nil?

    sizes = extract_sizes(img, 'photo_')
    { photo: img.attributes['src'].value }.
      merge(sizes)
  end

  def extract_sizes(tag, prefix)
    style = tag.attributes['style']&.value
    return {} if style.nil?

    w = style.match(/width:\s*([0-9a-z]+)/ui)
    h = style.match(/height:\s*([0-9a-z]+)/ui)
    { :"#{prefix}width" => w[1], :"#{prefix}height" => h[1] }
  end
end

Prod.new.call
