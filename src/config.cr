require "yaml"

module TsmHealthCheck
  class Config
    include YAML::Serializable

    @[YAML::Field(key: "checks")]
    property checks : Array(Check)

    def self.load(from = file)
      content = File.read(from)
      self.from_yaml(content)
    end

    def each_with_checks
      checks.each { |check| yield(check) }
    end
  end

  class Check
    include YAML::Serializable

    @[YAML::Field(key: "name")]
    property name : String

    @[YAML::Field(key: "endpoint")]
    property endpoint : String

    @[YAML::Field(key: "up")]
    property up : Up

    @[YAML::Field(key: "down")]
    property down : Down
  end

  class Up
    include YAML::Serializable

    @[YAML::Field(key: "timeout")]
    property timeout : Int32

    @[YAML::Field(key: "status_code")]
    property status_code : Int32

    @[YAML::Field(key: "json")]
    property json : Json

    @[YAML::Field(key: "response")]
    property response : Response
  end

  class Json
    include YAML::Serializable

    @[YAML::Field(key: "path")]
    property path : String

    @[YAML::Field(key: "value")]
    property value : String
  end

  class Response
    include YAML::Serializable

    @[YAML::Field(key: "status_code")]
    property status_code : String

    @[YAML::Field(key: "content_type")]
    property content_type : String

    @[YAML::Field(key: "body")]
    property body : String
  end

  class Down
    include YAML::Serializable

    @[YAML::Field(key: "response")]
    property response : Response
  end
end
