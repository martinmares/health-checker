require "option_parser"
require "colorize"
require "log"

module TsmHealthCheck
  class ArgParser
    getter args
    @args : Hash(Symbol, String)

    def initialize
      @args = Hash(Symbol, String).new
    end

    def parse
      args = Hash(Symbol, String).new
      OptionParser.parse do |parser|
        parser.banner = "Usage: tsm-health-check [arguments]"
        parser.on("-c CONFIG", "--config=CONFIG", "Specifies the name of the configuration file") do |_config|
          args[:config] = _config
        end
        parser.on("-h", "--help", "Show this help") do
          puts parser
          exit
        end
        parser.invalid_option do |flag|
          puts "#{"Error".colorize(:red)}: #{flag} is not a valid option."
          STDERR.puts parser
          exit(1)
        end
      end

      @args = args
    end

    def check
      unless @args.has_key?(:config)
        puts "#{"Error".colorize(:red)}: config file must be specified (-c CONFIG or --config=CONFIG)."
        exit(1)
      end
    end
  end
end
