require 'json'

class JsonConvertService

  def self.call(json)
    @data = JSON.parse(json)
    parse
  end

  private

  def self.parse
    xml = []
    xml << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    xml << "<document>"

    @data.each do |key, value|
      xml << "<data id=\"#{key}\">"
      xml << build_metadata(value['metadata']) if value['metadata']
      xml << build_rows(value['columns'], value['data']) if value['columns'] && value['data']
      xml << "</data>"
    end

    xml << "</document>"
    xml.join("\n")
  end

  def self.build_metadata(metadata)
    xml = []
    xml << "<metadata>"
    xml << "<columns>"
    metadata.each do |name, attrs|
      xml << "<column name=\"#{name}\" #{attrs.map {|k, v| "#{k}=\"#{v}\"" }.compact.join(" ")}/>"
    end
    xml << "</columns>"
    xml << "</metadata>"
    xml.join("\n")
  end

  def self.build_rows(columns, data)
    xml = []
    xml << "<rows>"
    data.each do |row|
      xml << "<row " + columns.each_with_index.map {|col, idx| "#{col}=\"#{row[idx]}\"" }.compact.join(" ") + "/>"
    end
    xml << "</rows>"
    xml.join("\n")
  end

end
