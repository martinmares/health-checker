require "yaml"

module HealthChecker
  class Config
    include YAML::Serializable

    @[YAML::Field(key: "html")]
    property html : Html

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

  class Html
    include YAML::Serializable

    @[YAML::Field(key: "title")]
    property title : String

    @[YAML::Field(key: "header")]
    property header : String

    @[YAML::Field(key: "footer")]
    property footer : String
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

    @[YAML::Field(key: "request")]
    property request : Request

    @[YAML::Field(key: "response")]
    property response : Response
  end

  class Request
    include YAML::Serializable

    @[YAML::Field(key: "timeout")]
    property timeout : Int32

    @[YAML::Field(key: "status_code")]
    property status_code : Int32

    @[YAML::Field(key: "content_type")]
    property content_type : String

    @[YAML::Field(key: "rules")]
    property rules : Array(Rule)
  end

  class Rule
    include YAML::Serializable

    @[YAML::Field(key: "type")]
    property type : String

    @[YAML::Field(key: "path", emit_null: true)]
    property path : String?

    @[YAML::Field(key: "includes")]
    property includes : String
end

  class Response
    include YAML::Serializable

    @[YAML::Field(key: "status_code")]
    property status_code : Int32

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
