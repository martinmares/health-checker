require "yaml"
require "../src/checks"

module TsmHealthCheck
  class Config
    @config_yaml : ConfigYaml

    def initialize(@config_yaml)
    end

    def self.load(from = file)
      content = File.read(from)
      config_yaml = ConfigYaml.from_yaml(content)
      self.new(config_yaml)
    end

    def each_with_checks
      @config_yaml.checks.each { |check| yield(check) }
    end
  end
end
