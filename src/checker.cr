require "crest"
require "timeout"
require "colorize"
require "http/client"
require "socket"

require "../src/config"
require "../src/json_parser"

module HealthChecker
  class Checker
    # Types
    TYPE_JSON = "json"
    TYPE_TEXT = "text"

    # Rule types
    RULE_TYPE_JSON_PATH     = "json_path"
    RULE_TYPE_RESPONSE_BODY = "response_body"

    # Check types
    CHECK_TYPE_HTTP = "http"
    CHECK_TYPE_TCP  = "tcp"

    def self.probe(check)
      get(check)
    rescue ex
      Log.error { "Server error: \"#{ex}\"" }
      {500, "Internal Server Error (\"#{ex}\")"}
    end

    def self.get(check)
      ch = Channel({Int32, String}).new

      check_type = if check.endpoint.is_a?(String)
                     CHECK_TYPE_HTTP
                   elsif check.tcp && check.tcp.is_a?(Tcp)
                     CHECK_TYPE_TCP
                   end

      Log.info { "Detected type: #{check_type}" }

      spawn do
        begin
          case check_type
          when CHECK_TYPE_HTTP
            uri = URI.parse(check.endpoint.as(String))
            http_client = HTTP::Client.new(
              host: uri.host.as(String),
              port: uri.port.as(Int32),
              tls: uri.scheme == "https" ? OpenSSL::SSL::Context::Client.insecure : nil)
            http_client.read_timeout = check.up.request.timeout
            resp = Crest.get(uri.to_s,
              logging: true,
              http_client: http_client,
              headers: {"Accept" => check.up.request.content_type})
            ch.send({resp.status_code, resp.body})
          when CHECK_TYPE_TCP
            tcp = check.tcp.as(Tcp)
            TCPSocket.open(tcp.host, tcp.port) {
              ch.send({200, "Tcp check OK!"})
            }
          end
        rescue ex
          case check_type
          when CHECK_TYPE_HTTP
            Log.error { "Http client error: \"#{ex}\", uri: \"#{uri}\"" }
          when CHECK_TYPE_TCP
            tcp = check.tcp.as(Tcp)
            ch.send({500, "Tcp check FAILED!"})
            Log.error { "Tcp client error: \"#{ex}\", host: \"#{tcp.host}\", port: \"#{tcp.port}\"" }
          end
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
          path_value = JsonParser.get_value(body, rule.path)
          Log.info { "JsonParser: path_value=#{path_value}, body=#{body}, rule.path=#{rule.path}" }
          if path_value
            case path_value
            when .includes? rule.includes
              counter_check_ok += 1
              Log.info { "#{"OK".colorize(:green)} - rule type \"#{rule.type}\", path: \"#{rule.path}\", includes? \"#{rule.includes}\"" }
            else
              Log.info { "#{"NOT OK".colorize(:red)} - rule type \"#{rule.type}\", path: \"#{rule.path}\", includes? \"#{rule.includes}\"" }
            end
          else
            Log.error { "Value for path \"#{rule.path}\" not found!" }
          end
        when TYPE_TEXT
          case body
          when .includes? rule.includes
            counter_check_ok += 1
            Log.info { "#{"OK".colorize(:green)} - rule type \"#{rule.type}\", includes? \"#{rule.includes}\"" }
          else
            Log.info { "#{"NOT OK".colorize(:red)} - rule type \"#{rule.type}\", includes? \"#{rule.includes}\"" }
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
