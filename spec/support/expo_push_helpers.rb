# frozen_string_literal: true

module ExpoPushHelpers
  def stub_expo_push_success
    mock_response = instance_double(Faraday::Response,
                                    success?: true,
                                    body: { 'data' => { 'status' => 'ok', 'id' => 'receipt-123' } })
    mock_client_instance = instance_double(HttpClientService, post: mock_response)
    allow(HttpClientService).to receive(:new).and_return(mock_client_instance)
    mock_client_instance
  end

  def stub_expo_push_device_not_registered
    mock_response = instance_double(Faraday::Response,
                                    success?: true,
                                    body: {
                                      'data' => {
                                        'status' => 'error',
                                        'message' => 'DeviceNotRegistered',
                                        'details' => { 'error' => 'DeviceNotRegistered' }
                                      }
                                    })
    mock_client_instance = instance_double(HttpClientService, post: mock_response)
    allow(HttpClientService).to receive(:new).and_return(mock_client_instance)
    mock_client_instance
  end

  def stub_expo_push_http_failure(error_body = 'Internal Server Error')
    mock_response = instance_double(Faraday::Response,
                                    success?: false,
                                    body: error_body)
    mock_client_instance = instance_double(HttpClientService, post: mock_response)
    allow(HttpClientService).to receive(:new).and_return(mock_client_instance)
    mock_client_instance
  end
end

RSpec.configure do |config|
  config.include ExpoPushHelpers
end
