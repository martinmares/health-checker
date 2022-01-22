require "crest"
require "../src/config"

module TsmHealthCheck
  class Checker
    def self.probe(check)
      resp = get(check)
      { resp.status_code, resp.body }
    rescue ex
      { -1, "Error \"#{ex}\" occured!" }
    end

    def self.get(check)
      uri = URI.parse(check.endpoint)
      client = HTTP::Client.new(uri)
      connect_timeout = check.up.connect_timeout
      read_timeout = check.up.read_timeout
      Log.info { "connect_timeout: #{connect_timeout}"}
      Log.info { "read_timeout: #{read_timeout}"}
      client.connect_timeout = connect_timeout.second
      client.read_timeout = read_timeout.second

      case uri.scheme
      when "https"
        Crest.get(uri.to_s, http_client: client, logging: true, json: true, tls: OpenSSL::SSL::Context::Client.insecure)
      else
        Crest.get(uri.to_s, http_client: client, logging: true, json: true)
      end
    end
  end
end
