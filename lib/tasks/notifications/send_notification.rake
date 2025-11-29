# frozen_string_literal: true

require 'faraday'

namespace :notifications do
  desc 'Send a push notification. Usage: rake notifications:send_notification[title,subtitle,body,push_token,channel]'
  task :send_notification, %i[title subtitle body push_token channel] => :environment do |_t, args|
    args.with_defaults(
      title: '',
      subtitle: '',
      body: '',
      push_token: '',
      channel: 'default'
    )

    message = {
      'to' => args[:push_token],
      'title' => args[:title],
      'subtitle' => args[:subtitle],
      'body' => args[:body],
      'channel' => args[:channel]
    }

    puts 'Sending notification with:'
    puts "Title: #{args[:title]}"
    puts "Subtitle: #{args[:subtitle]}"
    puts "Body: #{args[:body]}"
    puts "Push Token: #{args[:push_token]}"
    puts "Channel: #{args[:channel]}"

    begin
      conn = Faraday.new(
        url: 'https://exp.host/--/api/v2/push/send',
        headers: {
          'Accept' => 'application/json',
          'Accept-encoding': 'gzip, deflate',
          'Content-Type': 'application/json'
        }
      )
      resp = conn.post do |req|
        req.body = message.to_json
      end

      puts "Response status code: #{resp.status}"
      puts "Response headers: #{resp.headers}"
      puts "Response body: #{resp.body}"
    rescue StandardError => e
      Rails.logger.error("Notification request failed: #{e}")
    end
  end
end
