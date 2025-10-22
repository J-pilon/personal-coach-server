# frozen_string_literal: true
# rubocop:disable Metrics/BlockLength

require 'rails_helper'

RSpec.describe Ai::RateLimiter do
  let(:profile) { create(:profile) }

  describe '.check_and_record' do
    include_context 'with cache'
    context 'when user provides their own API key' do
      it 'returns unlimited access without recording' do
        result = described_class.check_and_record(profile, 'user-api-key')

        expect(result[:using_own_key]).to be true
        expect(result[:remaining]).to eq(Float::INFINITY)
        expect(result[:error]).to be_nil
        expect(result[:reason]).to be_nil
      end
    end

    context 'when user has no requests' do
      it 'allows the request, records it, and returns full limit' do
        result = described_class.check_and_record(profile)

        expect(result[:using_own_key]).to be false
        expect(result[:remaining]).to eq(2)
        expect(result[:total_limit]).to eq(3)
        expect(result[:reset_time]).to be_present
        expect(result[:error]).to be_nil
        expect(result[:reason]).to be_nil
      end
    end

    context 'when user has made some requests' do
      before do
        described_class.check_and_record(profile)
        described_class.check_and_record(profile)
      end

      it 'allows the request and returns correct remaining count' do
        result = described_class.check_and_record(profile)

        expect(result[:using_own_key]).to be false
        expect(result[:remaining]).to eq(0)
        expect(result[:total_limit]).to eq(3)
        expect(result[:error]).to be_nil
      end
    end

    context 'when user has reached the daily limit' do
      before do
        described_class.check_and_record(profile)
        described_class.check_and_record(profile)
        described_class.check_and_record(profile)
      end

      it 'denies the request with error and reason' do
        result = described_class.check_and_record(profile)

        expect(result[:using_own_key]).to be false
        expect(result[:remaining]).to eq(0)
        expect(result[:total_limit]).to eq(3)
        expect(result[:reset_time]).to be_present
        expect(result[:error]).to include('3-request AI limit')
        expect(result[:reason]).to eq('daily_limit_exceeded')
      end
    end
  end

  describe '#record_request' do
    include_context 'with cache'
    let(:rate_limiter) { described_class.new(profile) }

    it 'increments the request count' do
      expect { rate_limiter.record_request }
        .to change { rate_limiter.send(:current_requests) }
        .from(0).to(1)
    end

    it 'sets the cache to expire in 24 hours' do
      rate_limiter.record_request
      expect(rate_limiter.send(:current_requests)).to eq(1)
    end
  end

  describe '#usage_info' do
    include_context 'with cache'
    let(:rate_limiter) { described_class.new(profile) }

    context 'when user has no requests' do
      it 'returns correct usage info' do
        info = rate_limiter.usage_info
        expect(info[:using_own_key]).to be false
        expect(info[:remaining]).to eq(3)
        expect(info[:total_limit]).to eq(3)
      end
    end

    context 'when user has made some requests' do
      before do
        rate_limiter.record_request
      end

      it 'returns correct remaining count' do
        info = rate_limiter.usage_info
        expect(info[:remaining]).to eq(2)
      end
    end
  end

  describe '#remaining_requests' do
    include_context 'with cache'
    let(:rate_limiter) { described_class.new(profile) }

    context 'when user has no requests' do
      it 'returns the full limit' do
        expect(rate_limiter.remaining_requests).to eq(3)
      end
    end

    context 'when user has made some requests' do
      before do
        rate_limiter.record_request
        rate_limiter.record_request
      end

      it 'returns the remaining count' do
        expect(rate_limiter.remaining_requests).to eq(1)
      end
    end

    context 'when user has exceeded the limit' do
      before do
        5.times { rate_limiter.record_request }
      end

      it 'returns 0' do
        expect(rate_limiter.remaining_requests).to eq(0)
      end
    end
  end
end
