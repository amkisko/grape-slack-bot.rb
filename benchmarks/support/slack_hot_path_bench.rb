# frozen_string_literal: true

# Shared helpers for benchmarks/load.rb (HMAC verify + synthetic Slack API
# request/response path).

require "active_support/security_utils"
require "json"
require "openssl"

require "faraday"

require "slack_bot"

module SlackBot
  module Bench
    module SlackHotPath
      module_function

      def require_polyrun_pressure!
        if ENV["PRESSURE_POLYRUN_LIB"] && !ENV["PRESSURE_POLYRUN_LIB"].empty?
          lib = File.expand_path(ENV["PRESSURE_POLYRUN_LIB"])
          $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
        end

        require "polyrun/benchmark/pressure"
        # ProcessSample walks ObjectSpace / shells to `ps`; both dominate this harness.
        sample = Polyrun::Benchmark::Pressure::ProcessSample
        sample.singleton_class.send(:define_method, :heap_bytes) { 0 }
        sample.singleton_class.send(:define_method, :rss_bytes) { 0 }
      end

      def json_at_least_bytes(base, target_bytes)
        need = [target_bytes, 1].max
        pad = +""
        loop do
          payload = base.merge("pad" => pad)
          json = JSON.generate(payload)
          return json if json.bytesize >= need

          pad << "x"
        end
      end

      def json_payload_bytes(target_kb)
        json_at_least_bytes({"bench" => "slack"}, target_kb * 1024)
      end

      def slack_ok_json_bytes(target_kb)
        json_at_least_bytes({"ok" => true, "bench" => "ok"}, target_kb * 1024)
      end

      def faraday_json_response(status, body_string)
        Faraday::Response.new(
          {
            status: status,
            body: body_string,
            response_headers: {"Content-Type" => "application/json; charset=utf-8"}
          }
        )
      end

      def slack_signature_hex(secret, timestamp, body)
        sig_basestring = "v0:#{timestamp}:#{body}"
        digest = OpenSSL::HMAC.digest("SHA256", secret, sig_basestring)
        "v0=" + digest.unpack1("H*")
      end

      def slack_signature(secret, timestamp, body)
        slack_signature_hex(secret, timestamp, body)
      end

      def verify_hmac!(signing_secret, timestamp, body, slack_signature)
        sig_basestring = "v0:#{timestamp}:#{body}"
        digest_bin = OpenSSL::HMAC.digest("SHA256", signing_secret, sig_basestring)
        hex_part = slack_signature.delete_prefix("v0=")
        raise "signature mismatch" unless ActiveSupport::SecurityUtils.secure_compare(digest_bin, [hex_part].pack("H*"))

        true
      end

      def run_hmac_only!(reps, signing_secret, body_kb, label:, gc_start: false)
        timestamp = Time.now.to_i.to_s
        body = json_payload_bytes(body_kb)
        signature = slack_signature(signing_secret, timestamp, body)

        Polyrun::Benchmark::Pressure.measure(label: label, ops: reps, gc_start: gc_start, extras: {}) do
          reps.times do
            verify_hmac!(signing_secret, timestamp, body, signature)
          end
        end
      end

      def run_api_pipeline!(
        name,
        reps,
        signing_secret,
        body_kb,
        data_touches,
        label_suffix: nil,
        targets: nil,
        gc_start: false
      )
        timestamp = Time.now.to_i.to_s
        body = json_payload_bytes(body_kb)
        signature = slack_signature(signing_secret, timestamp, body)

        response_json = slack_ok_json_bytes(body_kb)
        request_bytes = 0
        response_bytes = 0
        ops = reps * (3 + data_touches)

        label = label_suffix ? "#{name}_#{label_suffix}" : name
        req_json_cache = {"channel" => "C1", "text" => body}.to_json

        result = Polyrun::Benchmark::Pressure.measure(
          label: label,
          ops: ops,
          gc_start: gc_start,
          extras: {"targets" => targets}
        ) do
          reps.times do
            verify_hmac!(signing_secret, timestamp, body, signature)

            request_bytes += req_json_cache.bytesize

            faraday_response = faraday_json_response(200, response_json)
            response_bytes += response_json.bytesize

            resp = SlackBot::ApiResponse.new { faraday_response }
            resp.ok?
            resp.error
            resp.rate_limited?
            data_touches.times { resp.data }
            resp.slack_error?
            resp.authentication_error?
          end
        end

        result["metrics"]["network_in_bytes"] += request_bytes
        result["metrics"]["network_out_bytes"] += response_bytes
        result["report"] = Polyrun::Benchmark::Pressure.format_report(result)
        result
      end

      def run_api_response_only!(reps, body_kb, data_touches, label:, gc_start: false)
        response_json = slack_ok_json_bytes(body_kb)
        response_bytes = 0
        ops = reps * (3 + data_touches)

        result = Polyrun::Benchmark::Pressure.measure(
          label: label,
          ops: ops,
          gc_start: gc_start,
          extras: {}
        ) do
          reps.times do
            faraday_response = faraday_json_response(200, response_json)
            response_bytes += response_json.bytesize

            resp = SlackBot::ApiResponse.new { faraday_response }
            resp.ok?
            resp.error
            resp.rate_limited?
            data_touches.times { resp.data }
            resp.slack_error?
            resp.authentication_error?
          end
        end

        result["metrics"]["network_out_bytes"] += response_bytes
        result["report"] = Polyrun::Benchmark::Pressure.format_report(result)
        result
      end

      def scale_targets_for_ops(targets, baseline_ops, new_ops)
        return targets if baseline_ops.nil? || baseline_ops <= 0 || new_ops.nil?

        ratio = new_ops.to_f / baseline_ops
        targets.transform_values { |v| v.nil? ? nil : v * ratio }
      end

      def env_int(name, default)
        Integer(ENV.fetch(name, default.to_s))
      end
    end
  end
end
