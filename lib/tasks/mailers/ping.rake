# frozen_string_literal: true

namespace :mailers do
  desc 'Send a SendGrid deliverability ping. Usage: rake mailers:ping[recipient@example.com]'
  task :ping, [:recipient] => :environment do |_t, args|
    recipient = args[:recipient].presence || ENV.fetch('MAIL_PING_RECIPIENT', nil)

    abort 'Recipient required. Pass as arg or set MAIL_PING_RECIPIENT.' if recipient.blank?

    puts "Sending TestMailer#ping to #{recipient} via #{ActionMailer::Base.delivery_method}..."
    TestMailer.ping(recipient).deliver_now
    puts 'Sent. Check the inbox (and SendGrid Activity Feed) to confirm delivery.'
  end
end
