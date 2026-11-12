require_relative 'boot'
require 'json'
require 'nokogiri'

class Prod
  def call
    data = {}

    File.open('data/messages.html') do |f|
      text = Nokogiri::HTML(f.read)

      data[:messages] = text.css('.page_body .history .message').each.with_object([]) do |msg, arr|
        obj = {}
        msg_date = msg.css('.date.details').first
        if msg_date
          obj[:published_short] = msg_date.content
          obj[:published] = msg_date.attributes['title'].value
        end

        obj[:external_id] = msg.attributes['id']&.value

        arr << obj
      end
      pp data[:messages].size, data[:messages].last(5)
    end
  end
end

Prod.new.call
