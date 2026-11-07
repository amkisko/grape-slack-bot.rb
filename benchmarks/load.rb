#!/usr/bin/env ruby
# frozen_string_literal: true

$stdout.sync = true
$stderr.sync = true

# Pressure / load bench: Slack request HMAC verification + SlackBot::ApiResponse hot paths.
#
# Usage:
#   make bench-load
#   bundle exec ruby benchmarks/load.rb
#   SCENARIO=matrix BODY_KB=8 DATA_TOUCHES=5 REPS=2000 bundle exec ruby benchmarks/load.rb
#
# Env:
#   SCENARIO=matrix|hmac|api (default matrix)
#   REPS — timed repetitions per scenario row (default 400)
#   BODY_KB — JSON request/response payload size scale (approximate, default 8)
#   DATA_TOUCHES — extra #data calls per response in the api row (default 4)
#   TARGET_FACTOR — next-round resource ceiling vs baseline (default 0.85)
#   SLACK_SIGNING_SECRET — optional override (default: synthetic 64-char secret)
#   PRESSURE_POLYRUN_LIB — optional path to polyrun `lib/` (default: bundled polyrun gem)

require "bundler/setup"

lib = File.expand_path("../lib", __dir__)
support = File.expand_path("support", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
$LOAD_PATH.unshift(support) unless $LOAD_PATH.include?(support)

require "slack_hot_path_bench"

SlackBot::Bench::SlackHotPath.require_polyrun_pressure!

H = SlackBot::Bench::SlackHotPath

module SlackBot
  module Bench
    module Load
      module_function

      def run!
        factor = ENV.fetch("TARGET_FACTOR", Polyrun::Benchmark::Pressure::DEFAULT_TARGET_FACTOR.to_s).to_f
        scenario = ENV.fetch("SCENARIO", "matrix")
        reps = H.env_int("REPS", 400)
        body_kb = H.env_int("BODY_KB", 8)
        data_touches = H.env_int("DATA_TOUCHES", 4)

        signing_secret = ENV.fetch("SLACK_SIGNING_SECRET", "z" * 64)

        puts "grape-slack-bot pressure scenario=#{scenario} reps=#{reps} body_kb=#{body_kb} data_touches=#{data_touches}"

        results =
          case scenario
          when "hmac" then [H.run_hmac_only!(reps, signing_secret, body_kb, label: "hmac_verify")]
          when "api" then [H.run_api_pipeline!("api_response_data_matrix", reps, signing_secret, body_kb, data_touches)]
          when "matrix" then run_matrix!(reps, signing_secret, body_kb, data_touches, factor)
          else
            raise "Unknown SCENARIO=#{scenario.inspect}"
          end

        path = Polyrun::Benchmark::Pressure.write_results!(results, repository_root: File.expand_path("..", __dir__))
        results.each { |row| puts row["report"] }
        puts "wrote #{path}"
        exit_code = (results.any? { |row| row["pass"] == false }) ? 1 : 0
        exit exit_code
      end

      def run_matrix!(reps, signing_secret, body_kb, data_touches, factor)
        baseline_hmac = H.run_hmac_only!(reps, signing_secret, body_kb, label: "baseline_hmac_verify")
        baseline_api = H.run_api_pipeline!(
          "baseline_api_response",
          reps,
          signing_secret,
          body_kb,
          data_touches,
          label_suffix: nil
        )
        targets = Polyrun::Benchmark::Pressure.targets_from(baseline_api["metrics"], factor: factor)

        hotter_reps = (reps * 1.5).ceil
        hot_body_kb = body_kb + 4
        pressure_ops = hotter_reps * (3 + data_touches + 2)
        pressure_targets = H.scale_targets_for_ops(targets, baseline_api["ops"], pressure_ops)
        # Bytes/op grow with BODY_KB and with extra #data calls; ops-only scaling is too tight for net=*.
        pressure_targets["network_in_bytes"] = nil
        pressure_targets["network_out_bytes"] = nil
        # Wall/CPU also reflect larger payloads and more #data calls per iteration than a plain ops ratio models.
        pressure_targets["wall_s"] = nil
        pressure_targets["cpu_s"] = nil

        pressure = H.run_api_pipeline!(
          "pressure_api_response",
          hotter_reps,
          signing_secret,
          hot_body_kb,
          data_touches + 2,
          label_suffix: "#{hotter_reps}x#{hot_body_kb}kb",
          targets: pressure_targets
        )

        [baseline_hmac, baseline_api, pressure]
      end
    end
  end
end

SlackBot::Bench::Load.run! if $PROGRAM_NAME == __FILE__
