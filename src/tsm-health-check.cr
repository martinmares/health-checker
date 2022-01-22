require "yaml"
require "kemal"
require "tallboy"
require "benchmark"
require "colorize"
require "markd"
require "ecr"

require "../src/config"
require "../src/arg_parser"
require "../src/html_utils"
require "../src/checker"

module TsmHealthCheck
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
        headers = ["Check name", "Try it!"]
        data_rows = [] of Array(String)

        @config.each_with_checks do |check|
          data_rows << [check.name, "<a href='/check/#{check.name}'>/check/#{check.name}</a>"]
        end

        _table = HtmlUtils.table_builder(headers, data_rows)
        render "src/views/index.ecr"
      end

      get "/mock/timeout/:sec" do |env|
        sec = env.params.url["sec"]
        sleep(sec.to_i)
        "Ok - after #{sec}s of sleeping ..."
      end

      @config.each_with_checks do |check|
        get "/check/#{check.name}" do |env|
          status_code, body = Checker.probe(check)
          case {status_code, body}
          when {check.up.status_code, _}
            Log.info { "probe status_code: #{status_code}, body: #{body}" }
            env.response.content_type = check.up.response.content_type
            check.up.response.body
          else
            Log.error { "probe status_code: #{status_code}, body: #{body}" }
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
