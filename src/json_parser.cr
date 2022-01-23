require "json"

module HealthChecker
  class JsonParser
    def self.get_value(data, path)
      result : String | Nil = nil
      begin
        if data && path
          json = JSON.parse(data)
          paths = path.split(".").reject(&.empty?)
          result = search_path(json, paths)
        end
      rescue
      end

      result
    end

    def self.search_path(json, paths, index = 0)
      return nil if index > 100 # sanity check!
      if json.as_h?
        field = paths[index]
        if index == (paths.size - 1) && json[field].as_s?
          return json[field].as_s
        elsif index == (paths.size - 1) && json[field].as_i?
          return json[field].as_i.to_s
        else
          search_path(json[field], paths, index + 1)
        end
      end
    end
  end
end
