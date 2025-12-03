# frozen_string_literal: true

class HttpClientService
  class HttpError < StandardError
    attr_reader :response

    def initialize(message, response = nil)
      @response = response
      super(message)
    end
  end

  class ConnectionError < HttpError; end
  class TimeoutError < HttpError; end
  class ClientError < HttpError; end
  class ServerError < HttpError; end

  MAX_RETRIES = 3
  DEFAULT_TIMEOUT = 30
  DEFAULT_OPEN_TIMEOUT = 10
  RETRYABLE_ERRORS = [Faraday::ConnectionFailed, Faraday::TimeoutError].freeze

  attr_reader :url

  def initialize(url, options = {})
    @url = url
    @http_client = options[:http_client] || Faraday
    @headers = options[:headers] || default_headers
    @timeout = options[:timeout] || DEFAULT_TIMEOUT
    @open_timeout = options[:open_timeout] || DEFAULT_OPEN_TIMEOUT
    @raise_on_failure = options[:raise_on_failure] || false
    @max_retries = options[:max_retries] || MAX_RETRIES
  end

  def get(endpoint = '', params: {})
    call(:get, endpoint: endpoint, params: params)
  end

  def post(endpoint = '', payload: {})
    call(:post, endpoint: endpoint, payload: payload)
  end

  def put(endpoint = '', payload: {})
    call(:put, endpoint: endpoint, payload: payload)
  end

  def patch(endpoint = '', payload: {})
    call(:patch, endpoint: endpoint, payload: payload)
  end

  def delete(endpoint = '')
    call(:delete, endpoint: endpoint)
  end

  def call(method, endpoint: '', params: {}, payload: {})
    raise ArgumentError, 'HTTP method is required' if method.blank?

    with_retries do
      execute_request(method.to_sym, endpoint, params, payload)
    end
  end

  private

  def with_retries
    retries = 0

    begin
      yield
    rescue *RETRYABLE_ERRORS => e
      retries += 1
      unless retries <= @max_retries
        raise ConnectionError, "Request failed after #{@max_retries} attempts: #{e.message}"
      end

      Rails.logger.warn "[HttpClient] Request failed (attempt #{retries}/#{@max_retries}): #{e.message}"
      sleep(2**retries)
      retry
    end
  end

  def execute_request(method, endpoint, params, payload)
    start_time = Time.current
    Rails.logger.info "[HttpClient] #{method.upcase} #{@url}#{endpoint}"

    response = send_request(method, endpoint, params, payload)

    log_completion(response, start_time)
    handle_response_errors(response) if @raise_on_failure

    response
  end

  def send_request(method, endpoint, params, payload)
    case method
    when :get
      connection.get(endpoint) { |req| req.params = params }
    when :post
      connection.post(endpoint) { |req| req.body = payload }
    when :put
      connection.put(endpoint) { |req| req.body = payload }
    when :patch
      connection.patch(endpoint) { |req| req.body = payload }
    when :delete
      connection.delete(endpoint)
    else
      raise ArgumentError, "Unsupported HTTP method: #{method}"
    end
  end

  def connection
    @connection ||= @http_client.new(url: @url) do |f|
      f.request :json
      f.response :json
      f.headers = @headers
      f.options.timeout = @timeout
      f.options.open_timeout = @open_timeout
    end
  end

  def log_completion(response, start_time)
    duration = ((Time.current - start_time) * 1000).round(2)
    Rails.logger.info "[HttpClient] Completed #{response.status} in #{duration}ms"
  end

  def handle_response_errors(response)
    return if response.success?

    if response.status >= 500
      raise ServerError.new("Server error: #{response.status}", response)
    elsif response.status >= 400
      raise ClientError.new("Client error: #{response.status}", response)
    end
  end

  def default_headers
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end
end
