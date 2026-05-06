# frozen_string_literal: true

class TestMailer < ApplicationMailer
  def ping(recipient)
    @sent_at = Time.current
    @env = Rails.env

    mail(
      to: recipient,
      subject: "[Personal Coach] SendGrid deliverability ping (#{@env})"
    )
  end
end
