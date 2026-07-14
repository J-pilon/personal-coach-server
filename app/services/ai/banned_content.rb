# frozen_string_literal: true

module Ai
  module BannedContent
    PATTERNS = [
      /\bstreak\s+(?:lost|broken|dies?)\b/i,
      /\byou\s+(?:will|are\s+going\s+to)\s+fail\b/i,
      /\bdiagnos(?:e|is|ed)\b/i,
      /\bcure[sd]?\b/i,
      /\bmedical\s+advice\b/i,
      /\bfinancial\s+advice\b/i,
      /\bkill\s+yourself\b/i
    ].freeze

    module_function

    def contains?(text)
      return false if text.blank?

      PATTERNS.any? { |re| text.match?(re) }
    end

    def scan_deep(value)
      case value
      when String then contains?(value)
      when Hash then value.values.any? { |v| scan_deep(v) }
      when Array then value.any? { |v| scan_deep(v) }
      else false
      end
    end
  end
end
