# frozen_string_literal: true

require 'csv'

# Collects per-request timings from Rails' controller instrumentation while request specs run.
module RouteProfiler
  # Value object representing a single request sample
  class Sample
    attr_reader :dur_ms, :ctrl, :action, :status, :db_ms, :view_ms, :route_method, :path

    # rubocop:disable Metrics/ParameterLists
    def initialize(dur_ms:, ctrl:, action:, status:, db_ms:, view_ms:, route_method:, path:)
      @dur_ms = dur_ms
      @ctrl = ctrl
      @action = action
      @status = status
      @db_ms = db_ms
      @view_ms = view_ms
      @route_method = route_method
      @path = path
    end
    # rubocop:enable Metrics/ParameterLists
  end

  # Responsible for subscribing to Rails notifications and collecting request samples
  class Collector
    attr_reader :samples

    def initialize(sample_class: Sample)
      @sample_class = sample_class
      @samples = Hash.new { |h, k| h[k] = [] }
      @subscribed = false
      @subscriber = nil
    end

    def subscribe!
      return if @subscribed

      @subscribed = true

      @subscriber = ActiveSupport::Notifications.subscribe(
        'process_action.action_controller'
      ) do |_name, start, finish, _id, payload|
        collect_sample(start, finish, payload)
      end
    end

    private

    def collect_sample(start, finish, payload)
      dur_ms = (finish - start) * 1000.0
      route_method = (payload[:method] || 'GET').to_s.upcase
      route_path = extract_route_path(payload)

      key = "#{route_method} #{route_path}"

      @samples[key] << create_sample(dur_ms, route_method, route_path, payload)
    end

    def extract_route_path(payload)
      # Rails 7 usually includes :path; fall back to controller#action
      payload[:path] || "#{payload[:controller]}##{payload[:action]}"
    end

    def create_sample(dur_ms, route_method, route_path, payload)
      @sample_class.new(
        dur_ms: dur_ms,
        ctrl: payload[:controller],
        action: payload[:action],
        status: payload[:status],
        db_ms: payload[:db_runtime],
        view_ms: payload[:view_runtime],
        route_method: route_method,
        path: route_path
      )
    end

    def unsubscribe!
      ActiveSupport::Notifications.unsubscribe(@subscriber) if @subscriber
      @subscribed = false
      @subscriber = nil
    end
  end

  # Responsible for calculating metrics from collected samples
  class MetricsCalculator
    PERCENTILE_95 = 0.95

    def initialize(samples)
      @samples = samples
    end

    def calculate
      @samples.map do |key, arr|
        calculate_route_metrics(key, arr)
      end
    end

    private

    def calculate_route_metrics(key, arr)
      durs = arr.map(&:dur_ms).sort
      count = arr.size
      total = durs.sum
      mean = total / count
      p95 = calculate_percentile(durs, count)
      max = durs.last
      statuses = arr.group_by(&:status).transform_values(&:count)

      build_metrics_hash(key, arr.first, count, mean, p95, max, total, statuses)
    end

    # rubocop:disable Metrics/ParameterLists
    def build_metrics_hash(key, first_sample, count, mean, p95, max, total, statuses)
      {
        key: key,
        count: count,
        mean_ms: mean,
        p95_ms: p95,
        max_ms: max,
        total_ms: total,
        controller: first_sample.ctrl,
        action: first_sample.action,
        statuses: statuses
      }
    end
    # rubocop:enable Metrics/ParameterLists

    def calculate_percentile(sorted_values, count)
      index = (count * PERCENTILE_95).floor - 1
      sorted_values[index] || sorted_values.last
    end
  end

  # Abstract base class for formatters
  class Formatter
    def format(_metrics)
      raise NotImplementedError, "#{self.class} must implement #format"
    end
  end

  # Formats metrics for console output
  class ConsoleFormatter < Formatter
    HEADER_FORMAT = '%-45s %6s %10s %10s %10s  %s'

    def initialize(io: $stdout, top: 50)
      super()
      @io = io
      @top = top
    end

    def format(metrics)
      ranked = metrics.sort_by { |h| -h[:p95_ms] }

      print_header
      print_rows(ranked)
    end

    private

    def print_header
      @io.puts "\n=== Route timings from request specs (ranked by p95) ==="
      headers = ['ROUTE', 'count', 'mean(ms)', 'p95(ms)', 'max(ms)', 'statuses']
      @io.puts format_headers(HEADER_FORMAT, headers)
    end

    def format_headers(format, headers)
      format % headers
    end

    def print_rows(ranked)
      ranked.first(@top).each { |r| print_row(r) }
    end

    def print_row(metric)
      row = [metric[:key],
             metric[:count],
             metric[:mean_ms].round(1),
             metric[:p95_ms].round(1),
             metric[:max_ms].round(1),
             metric[:statuses].inspect]

      @io.puts format_headers(
        HEADER_FORMAT,
        row
      )
    end
  end

  # Formats metrics as CSV output
  class CsvFormatter < Formatter
    HEADERS = %w[route count mean_ms p95_ms max_ms total_ms controller action statuses_json].freeze

    def initialize(path:, io: $stdout)
      super()
      @path = path
      @io = io
    end

    def format(metrics)
      return if metrics.empty?

      ranked = metrics.sort_by { |h| -h[:p95_ms] }

      write_csv(ranked)
      @io.puts "\nCSV written to #{@path}"
    end

    private

    def write_csv(ranked)
      CSV.open(@path, 'wb') do |csv|
        csv << HEADERS
        ranked.each { |r| csv << build_csv_row(r) }
      end
    end

    def build_csv_row(metric)
      [
        metric[:key],
        metric[:count],
        metric[:mean_ms],
        metric[:p95_ms],
        metric[:max_ms],
        metric[:total_ms],
        metric[:controller],
        metric[:action],
        metric[:statuses].to_json
      ]
    end
  end

  # Module-level API for easy access
  class << self
    delegate :subscribe!, to: :collector

    delegate :unsubscribe!, to: :collector

    def report!(top: 50, io: $stdout, csv: 'tmp/route_profile_from_specs.csv', formatters: nil)
      metrics = MetricsCalculator.new(collector.samples).calculate

      formatters ||= default_formatters(top: top, io: io, csv: csv)
      formatters.each { |formatter| formatter.format(metrics) }
    end

    private

    def collector
      @collector ||= Collector.new
    end

    def default_formatters(top:, io:, csv:)
      [
        ConsoleFormatter.new(io: io, top: top),
        CsvFormatter.new(path: csv, io: io)
      ]
    end
  end
end

RSpec.configure do |config|
  # Enable with PROFILE_ROUTES=1 to avoid noise on normal runs.
  if ENV['PROFILE_ROUTES'] == '1'
    config.before(:suite) { RouteProfiler.subscribe! }
    config.after(:suite) { RouteProfiler.report!(top: (ENV['TOP'] || 50).to_i) }
  end
end
