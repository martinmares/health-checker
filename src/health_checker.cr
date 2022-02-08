require "yaml"
require "kemal"
require "tallboy"
require "benchmark"
require "colorize"
require "ecr"

require "../src/config"
require "../src/arg_parser"
require "../src/html_utils"
require "../src/checker"

module HealthChecker
  class App
    @config : Config
    @arg_pars : ArgParser

    def initialize
      @arg_pars = ArgParser.new
      @arg_pars.parse
      @arg_pars.check
      @config = Config.load from: @arg_pars.args[:config]
    end

    def run
      get "/" do
        headers = ["Name", "Try it!"]
        data_rows = [] of Array(String)

        @config.each_with_checks do |check|
          data_rows << [check.name, "<a href='/check/#{check.name}'>/check/#{check.name}</a>"]
        end

        _title = @config.html.title
        _header = @config.html.header
        _footer = @config.html.footer
        _table = HtmlUtils.table_builder(headers, data_rows)

        render "src/views/index.ecr"
      end

      get "/mock/timeout/:sec" do |env|
        sec = env.params.url["sec"]
        sleep(sec.to_i)
        "Ok - after #{sec}s of sleeping ..."
      end

      get "/healthz" do |env|
        env.response.content_type = "application/json"
        "{ \"status\": \"UP\", \"description\": \"The service is up and running.\" }"
      end

      @config.each_with_checks do |check|
        get "/check/#{check.name}" do |env|
          probe_result = Checker.probe(check)
          status_code, body = probe_result
          case {status_code, body}
          when {check.up.request.status_code, _}
            Log.info { "probe up: #{status_code}, body: #{body}" }
            env.response.status_code, env.response.content_type, response_body =
              Checker.evaluation_of(check, probe_result)
            response_body
          else
            Log.error { "probe down: #{status_code}, body: #{body}" }
            env.response.content_type = check.down.response.content_type
            env.response.status_code = check.down.response.status_code
            check.down.response.body
          end
        end
      end

      Kemal.run
    end
  end

  app = App.new
  app.run
end
