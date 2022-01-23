require "crest"
require "timeout"
require "colorize"

require "../src/config"

module HealthChecker
  class Checker
    TYPE_JSON               = "json"
    TYPE_TEXT               = "text"
    RULE_TYPE_JSON_PATH     = "json_path"
    RULE_TYPE_RESPONSE_BODY = "response_body"

    def self.probe(check)
      get(check)
    rescue ex
      Log.error { "Server error: \"#{ex}\"" }
      {500, "Internal Server Error (\"#{ex}\")"}
    end

    def self.get(check)
      ch = Channel({Int32, String}).new
      uri = URI.parse(check.endpoint)

      spawn do
        begin
          resp = Crest.get(uri.to_s, logging: true,
            headers: {"Content-Type" => check.up.request.content_type},
            tls: uri.scheme == "https" ? OpenSSL::SSL::Context::Client.insecure : nil)
          ch.send({resp.status_code, resp.body})
        rescue ex
          Log.error { "Http client error: \"#{ex}\", uri: \"#{uri}\"" }
        end
      end

      select
      when response = ch.receive
        status_code, body = response
        {status_code, body}
      when Timeout.after(check.up.request.timeout.second)
        {408, "Request Timeout"}
      end
    end

    def self.evaluation_of(check, probe)
      check_rules(check, probe)
    end

    def self.check_rules(check, probe)
      status_code, body = probe
      counter_check_ok = 0
      rules = check.up.request.rules

      rules.each do |rule|
        case rule.type
        when TYPE_JSON
          Log.info { "Check rule type #{TYPE_JSON}, path: #{rule.path}, includes? #{rule.includes}" }
        when TYPE_TEXT
          case body
          when .includes? rule.includes
            counter_check_ok += 1
            Log.info { "#{"OK".colorize(:green)} - rule type \"#{TYPE_TEXT}\", includes? \"#{rule.includes}\"" }
          else
            Log.info { "#{"NOT OK".colorize(:red)} - rule type \"#{TYPE_TEXT}\", includes? \"#{rule.includes}\"" }
          end
        else
          Log.error { "Don't known this rule #{rule.type}!" }
        end
      end

      Log.info { "Finished checking rules, rules.size=#{rules.size}, counter_check_ok=#{counter_check_ok}, status_code=#{status_code}, check.up.request.status_code=#{check.up.request.status_code}!" }

      if rules.size == counter_check_ok && status_code == check.up.request.status_code
        Log.info { "All rules #{"OK".colorize(:green)}" }
        {check.up.response.status_code, check.up.response.content_type, check.up.response.body}
      else
        Log.info { "Some rules #{"NOT OK".colorize(:red)}!" }
        {check.down.response.status_code, check.down.response.content_type, check.down.response.body}
      end
    end
  end
end
