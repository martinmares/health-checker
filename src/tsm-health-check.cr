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

      @config.each_with_checks do |check|
        get "/check/#{check.name}" do
          Log.info { "check for #{check.name.colorize(:green)}" }
          "<pre>#{check.name}: UP</pre>"
        end
      end

      Kemal.run
    end
  end

  app = App.new
  app.run
end
