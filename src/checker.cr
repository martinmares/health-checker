require "crest"
require "timeout"

require "../src/config"

module HealthChecker
  class Checker
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
          resp = Crest.get(uri.to_s, logging: true, json: true,
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
  end
end
