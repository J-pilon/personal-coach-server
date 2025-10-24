# frozen_string_literal: true

require 'csv'

# Collects per-request timings from Rails' controller instrumentation while request specs run.
module QueryProfiler
  # Value object representing a single request sample
  class Sample
    attr_reader :dur_ms, :row_count, :statement_name, :sql

    def initialize(dur_ms:, row_count:, statement_name:, sql:)
      @dur_ms = dur_ms
      @row_count = row_count
      @statement_name = statement_name
      @sql = sql
    end
  end

  # Responsible for subscribing to Rails notifications and collecting request samples
  class Collector
    attr_reader :samples

    # Framework queries that are typically not business logic
    FRAMEWORK_QUERY_PATTERNS = [
      /^BEGIN$/i,
      /^COMMIT$/i,
      /^ROLLBACK$/i,
      /^ROLLBACK TO SAVEPOINT/i,
      /^SAVEPOINT/i,
      /^RELEASE SAVEPOINT/i,
      /^SHOW /i,
      /^SET /i,
      /FROM pg_attribute/i,
      /FROM pg_index/i,
      /FROM pg_type/i,
      /FROM pg_collation/i,
      /FROM pg_namespace/i,
      /FROM pg_class/i,
      /pg_get_expr/i
    ].freeze

    def initialize(sample_class: Sample, filter_framework_queries: true)
      @sample_class = sample_class
      @samples = Hash.new { |h, k| h[k] = [] }
      @subscribed = false
      @subscriber = nil
      @filter_framework_queries = filter_framework_queries
    end

    def subscribe!
      return if @subscribed

      @subscribed = true

      @subscriber = ActiveSupport::Notifications.subscribe(
        'sql.active_record'
      ) do |_name, start, finish, _id, payload|
        collect_sample(start, finish, payload)
      end
    end

    private

    def collect_sample(start, finish, payload)
      dur_ms = (finish - start) * 1000.0
      row_count = payload[:row_count]
      statement_name = payload[:statement_name]
      sql = payload[:sql]

      return if @filter_framework_queries && framework_query?(sql)

      @samples[sql] << create_sample(sql, dur_ms, statement_name, row_count)
    end

    def framework_query?(sql)
      FRAMEWORK_QUERY_PATTERNS.any? { |pattern| sql.match?(pattern) }
    end

    def create_sample(sql, dur_ms, statement_name, row_count)
      @sample_class.new(
        sql: sql,
        dur_ms: dur_ms,
        statement_name: statement_name,
        row_count: row_count
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
        calculate_query_metrics(key, arr)
      end
    end

    private

    def calculate_query_metrics(key, arr)
      durs = arr.map(&:dur_ms).sort
      count = arr.size
      total = durs.sum
      mean = total / count
      p95 = calculate_percentile(durs, count)
      max = durs.last

      build_metrics_hash(key, arr.first, count, mean, p95, max, total)
    end

    # rubocop:disable Metrics/ParameterLists
    def build_metrics_hash(key, first_sample, count, mean, p95, max, total)
      {
        key: key,
        count: count,
        mean_ms: mean,
        p95_ms: p95,
        max_ms: max,
        total_ms: total
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
    HEADER_FORMAT = '%-80s %6s %10s %10s %10s'

    def initialize(io: $stdout, top: 50)
      super()
      @io = io
      @top = top
    end

    def format(metrics)
      ranked = metrics.sort_by { |h| -h[:p95_ms] }

      print_header
      print_rows(ranked)
      print_summary(ranked)
    end

    private

    def print_header
      @io.puts "\n#{'=' * 120}"
      @io.puts 'Query timings from request specs (ranked by p95)'
      @io.puts '=' * 120
      headers = ['SQL', 'count', 'mean(ms)', 'p95(ms)', 'max(ms)']
      @io.puts format_headers(HEADER_FORMAT, headers)
      @io.puts '-' * 120
    end

    def format_headers(format, headers)
      format % headers
    end

    def print_rows(ranked)
      ranked.first(@top).each { |r| print_row(r) }
    end

    def print_row(metric)
      row = [normalize_sql(metric[:key], max_length: 80),
             metric[:count],
             metric[:mean_ms].round(2),
             metric[:p95_ms].round(2),
             metric[:max_ms].round(2)]

      @io.puts format_headers(HEADER_FORMAT, row)
    end

    def print_summary(ranked)
      @io.puts '-' * 120
      @io.puts "Total queries tracked: #{ranked.length}"
      @io.puts "Showing top #{[@top, ranked.length].min} slowest queries"
      @io.puts '=' * 120
    end

    def normalize_sql(sql, max_length: 80)
      # Remove extra whitespace and newlines
      normalized = sql.gsub(/\s+/, ' ').strip

      # Truncate if longer than max_length
      if normalized.length > max_length
        "#{normalized[0...(max_length - 3)]}..."
      else
        normalized
      end
    end
  end

  # Formats metrics as CSV output
  class CsvFormatter < Formatter
    HEADERS = %w[SQL count mean_ms p95_ms max_ms total_ms].freeze

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
        normalize_sql(metric[:key]),
        metric[:count],
        metric[:mean_ms].round(2),
        metric[:p95_ms].round(2),
        metric[:max_ms].round(2),
        metric[:total_ms].round(2)
      ]
    end

    def normalize_sql(sql)
      # Remove extra whitespace and newlines
      normalized = sql.gsub(/\s+/, ' ').strip

      # Truncate if longer than 120 chars
      if normalized.length > 120
        "#{normalized[0...117]}..."
      else
        normalized
      end
    end
  end

  # Module-level API for easy access
  class << self
    attr_writer :filter_framework_queries

    delegate :subscribe!, to: :collector

    delegate :unsubscribe!, to: :collector

    def report!(top: 50, io: $stdout, csv: 'tmp/query_profile_from_specs.csv', formatters: nil)
      metrics = MetricsCalculator.new(collector.samples).calculate

      formatters ||= default_formatters(top: top, io: io, csv: csv)
      formatters.each { |formatter| formatter.format(metrics) }
    end

    def filter_framework_queries
      return @filter_framework_queries unless @filter_framework_queries.nil?

      true
    end

    private

    def collector
      @collector ||= Collector.new(filter_framework_queries: filter_framework_queries)
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
  # Enable with PROFILE_QUERIES=1 to avoid noise on normal runs.
  if ENV['PROFILE_QUERIES'] == '1'
    config.before(:suite) { QueryProfiler.subscribe! }
    config.after(:suite) { QueryProfiler.report!(top: (ENV['TOP'] || 50).to_i) }
  end
end
