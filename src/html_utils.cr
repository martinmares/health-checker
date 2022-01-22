module HealthChecker
  class HtmlUtils
    def self.table_builder(headers : Array(String), rows : Array(Array(String)))
      html = String.build do |str|
        str << "<table class='table table-hover table-sm'>"

        # Headers
        str << "<thead>"
        str << "<tr>"
        headers.each do |header|
          str << "<th scope='col'>#{header}</th>"
        end
        str << "</tr>"
        str << "</thead>"

        # Rows
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
  end
end
