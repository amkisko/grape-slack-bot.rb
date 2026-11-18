# frozen_string_literal: true

require "json"
require "grape"
require "rack/mock"
require "slack_bot"

module SlackSchemaBenchmark
  module_function

  def percentile(samples)
    samples.sort.fetch((samples.size * 0.95).ceil - 1)
  end

  def clock
    Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_microsecond)
  end

  def measure(operations, stages)
    cpu = Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID)
    allocated = GC.stat(:total_allocated_objects)
    wall = clock
    samples = stages.transform_values do |stage|
      Array.new(operations) do
        start = clock
        stage.call
        clock - start
      end
    end
    samples.transform_keys { |name| "#{name}_p95_us" }.transform_values { |values| percentile(values).round(2) }.merge(
      wall_ms: ((clock - wall) / 1_000).round(2),
      cpu_ms: ((Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID) - cpu) * 1_000).round(2),
      allocated: GC.stat(:total_allocated_objects) - allocated
    )
  end

  def calibrate
    ticks = [0, 0, 1, 10, 13, 20, 27, 1_000]
    singleton_class.alias_method(:real_clock, :clock)
    define_singleton_method(:clock) { ticks.shift }
    result = measure(1, parse: -> {}, rack: -> {}, dispatch: -> {})
    raise "Stage calibration failed" unless result.values_at("parse_p95_us", "rack_p95_us", "dispatch_p95_us", :wall_ms) == [1, 3, 7, 1.0]

    puts JSON.generate(result)
  ensure
    singleton_class.alias_method(:clock, :real_clock)
  end

  def rack_request(config)
    api = Class.new(Grape::API) do
      include SlackBot::GrapeExtension

      helpers { define_method(:slack_bot_config) { config } }
    end

    secret = "test_benchmark"
    ENV.update("SLACK_SIGNING_SECRET" => secret, "SLACK_TEAM_ID" => "T1")
    payload = JSON.generate(type: "block_actions", team: {id: "T1"}, user: {id: "U1", team_id: "T1"},
      actions: [{action_id: "approve", value: "yes"}])
    body = Rack::Utils.build_query(payload: payload)
    timestamp = Time.now.to_i.to_s
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "v0:#{timestamp}:#{body}")
    request = Rack::MockRequest.new(api)
    rack = lambda do
      response = request.post("/interactions", :input => body, "CONTENT_TYPE" => "application/x-www-form-urlencoded",
        "HTTP_X_SLACK_REQUEST_TIMESTAMP" => timestamp, "HTTP_X_SLACK_SIGNATURE" => "v0=#{signature}")
      raise response.body unless [200, 201].include?(response.status) && response.body == '{"handled":true}'
    end
    [payload, rack]
  end

  def run(mode)
    config = SlackBot::Config.new
    handler = if mode == "schema"
      Class.new(SlackBot::Schema::BlockActions) do
        action :approve, with: :approve

        def approve
          {handled: true}
        end
      end
    else
      Class.new(SlackBot::Interaction) do
        def call
          {handled: true} if payload.dig("actions", 0, "value") == "yes"
        end
      end
    end
    config.block_action(:approve, handler)
    payload, rack = rack_request(config)
    params = {payload: payload}
    endpoint = Object.new.extend(SlackBot::GrapeHelpers)
    endpoint.define_singleton_method(:slack_bot_config) { config }
    endpoint.define_singleton_method(:status) { |value| value }
    decoded = JSON.parse(payload)
    dispatch = -> { endpoint.route_interaction(payload: decoded, user: nil, params: params) }
    stages = {parse: -> { JSON.parse(payload) }, rack: rack, dispatch: dispatch}
    100.times { stages.each_value(&:call) }

    operations = Integer(ENV.fetch("SLACK_BENCH_REPS", "1000"))
    puts JSON.generate(measure(operations, stages).merge(mode: mode, operations: operations, fixture_bytes: payload.bytesize))
  end
end

if ARGV == ["--self-test"]
  SlackSchemaBenchmark.calibrate
else
  SlackSchemaBenchmark.run(ARGV.fetch(0, "legacy"))
end
