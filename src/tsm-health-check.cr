require "yaml"
require "kemal"
require "tallboy"
require "benchmark"
require "colorize"
require "markd"

require "../src/config"
require "../src/arg_parser"

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

    def table_builder(headers : Array(String), rows : Array(Array(String)))
      html = String.build do |str|
        str << "<table>"
        str << "<thead>"
        str << "<tr>"
        headers.each do |header|
          str << "<th>#{header}</th>"
        end
        str << "</tr>"
        str << "</thead>"

        str << "<tbody>"
        rows.each do |row|
          str << "<tr>"
          row.each do |col|
            str << "<td>#{col}</td>"
          end
          str << "</tr>"
        end
        str << "</tbody>"

        str << "</table>"
      end

      html.to_s
    end

    def run
      get "/" do
        headers = ["Check name", "Try it!"]
        data_rows = [] of Array(String)

        @config.each_with_checks do |check|
          data_rows << [check.name, "<a href='/check/#{check.name}'>/check/#{check.name}</a>"]
        end

        head = <<-HEAD
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
          <title>TSM health checks</title>
        HEAD

        foot = <<-FOOT
          <footer>
            <p>For <a href='https://tsm.datalite.cz'>TSM</a> product, developed by <a href="mailto:info@datalite.cz">DataLite</a></p>
          </footer>
        FOOT

        style = <<-CSS
          table, th, td {
            border: 1px solid black;
            border-collapse: collapse;
          }
          th, td {
            padding: 10px;
          }
        CSS

        "<!DOCTYPE html><html><head>#{head}<style>#{style}</style></head><body><main><h1>TSM health checks</h1>#{table_builder(headers, data_rows)}</main>#{foot}</body></html>"
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
