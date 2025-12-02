# frozen_string_literal: true

module Notifications
  class BaseService
    def initialize(profile, channels: nil)
      @profile = profile
      @preference = profile.notification_perference
      @channels = channels || default_channels
    end

    def call
      return [] unless should_send?

      notifications = []

      @channels.each do |channel|
        next unless channel_enabled?(channel)

        case channel.to_sym
        when :push
          notifications.concat(send_push_notifications)
        when :email
          notifications << send_email_notification if email_ready?
        end
      end

      notifications.compact
    end

    private

    def should_send?
      @preference.present? && !@preference.in_quiet_hours?
    end

    def channel_enabled?(channel)
      @preference.channel_enabled?(notification_type, channel)
    end

    def default_channels
      [:push]
    end

    def send_push_notifications
      @profile.push_tokens.map do |device_token|
        send_push_to_device(device_token)
      end
    end

    def send_push_to_device(device_token)
      notification = create_notification_record(:push, device_token)

      Notifications::Delivery::PushService.new(
        device_token: device_token,
        notification: notification
      ).deliver

      notification
    rescue StandardError => e
      notification&.update!(status: 'failed', error_message: e.message)
      Rails.logger.error("Push failed: #{e.message}")
      notification
    end

    # Placeholder for future email implementation
    def send_email_notification
      return nil unless email_ready?

      create_notification_record(:email)
      # Notifications::Delivery::EmailService.new(...).deliver
    end

    # Placeholder for future SMS implementation
    def send_sms_notification
      return nil unless sms_ready?

      create_notification_record(:sms)
      # Notifications::Delivery::SmsService.new(...).deliver
    end

    def email_ready?
      false  # Not implemented yet
    end

    def sms_ready?
      false  # Not implemented yet
    end

    def create_notification_record(channel, device_token = nil)
      Notification.create!(
        profile: @profile,
        device_token: device_token,
        notification_type: notification_type,
        channel: channel.to_s,
        title: notification_title,
        body: notification_body,
        data: notification_data,
        scheduled_for: Time.current
      )
    end

    def notification_type
      raise NotImplementedError
    end

    def notification_title
      raise NotImplementedError
    end

    def notification_body
      raise NotImplementedError
    end

    def notification_data
      {}
    end
  end
end
