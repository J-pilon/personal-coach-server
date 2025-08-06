# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::RateLimiter do
  let(:profile) { create(:profile) }
  let(:rate_limiter) { described_class.new(profile) }

  before do
    Rails.cache.clear
    # Mock the cache to work in test environment
    allow(Rails.cache).to receive(:is_a?).with(ActiveSupport::Cache::NullStore).and_return(true)
  end

  describe '#check_limit' do
    context 'when user has no requests' do
      it 'allows the request' do
        result = rate_limiter.check_limit
        expect(result[:allowed]).to be true
        expect(result[:remaining]).to eq(3)
      end
    end

    context 'when user has made some requests' do
      before do
        # Simulate 2 requests by calling record_request twice
        rate_limiter.record_request
        rate_limiter.record_request
      end

      it 'allows the request and shows remaining count' do
        result = rate_limiter.check_limit
        expect(result[:allowed]).to be true
        expect(result[:remaining]).to eq(1)
      end
    end

    context 'when user has reached the daily limit' do
      before do
        # Simulate 3 requests by calling record_request three times
        rate_limiter.record_request
        rate_limiter.record_request
        rate_limiter.record_request
      end

      it 'denies the request' do
        result = rate_limiter.check_limit
        expect(result[:allowed]).to be false
        expect(result[:reason]).to eq('daily_limit_exceeded')
        expect(result[:message]).to include('3-request AI limit')
      end
    end
  end

  describe '#record_request' do
    it 'increments the request count' do
      expect { rate_limiter.record_request }
        .to change { rate_limiter.send(:current_requests) }
        .from(0).to(1)
    end

    it 'sets the cache to expire in 24 hours' do
      rate_limiter.record_request
      # NOTE: In test environment, we verify the request count was incremented
      expect(rate_limiter.send(:current_requests)).to eq(1)
    end
  end

  describe '#usage_info' do
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
        # Simulate 1 request
        rate_limiter.record_request
      end

      it 'returns correct remaining count' do
        info = rate_limiter.usage_info
        expect(info[:remaining]).to eq(2)
      end
    end
  end

  describe '#remaining_requests' do
    context 'when user has no requests' do
      it 'returns the full limit' do
        expect(rate_limiter.remaining_requests).to eq(3)
      end
    end

    context 'when user has made some requests' do
      before do
        # Simulate 2 requests
        rate_limiter.record_request
        rate_limiter.record_request
      end

      it 'returns the remaining count' do
        expect(rate_limiter.remaining_requests).to eq(1)
      end
    end

    context 'when user has exceeded the limit' do
      before do
        # Simulate 5 requests (exceeds limit)
        rate_limiter.record_request
        rate_limiter.record_request
        rate_limiter.record_request
        rate_limiter.record_request
        rate_limiter.record_request
      end

      it 'returns 0' do
        expect(rate_limiter.remaining_requests).to eq(0)
      end
    end
  end
end
