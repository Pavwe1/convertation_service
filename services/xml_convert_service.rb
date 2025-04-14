class XmlConvertService

  def self.call(xml)
    @data = xml
    parse
  end

  private

  def self.parse
    result = {}

    @data.scan(/<data id="(.*?)">(.*?)<\/data>/m).each do |data_id, data_block|
      metadata = build_metadata(data_block.scan(/<column(.*?)\/>/m))
      data = build_data(data_block.scan(/<row(.*?)\/>/m), metadata)

      result[data_id.to_sym] = { metadata: metadata, columns: data[:columns], data: data[:data] }
    end

    custom_to_json(result)
  end

  def self.build_metadata(metadata)
    result = {}
    metadata.each do |column_content|
      column = {}

      column_content.first.scan(/(\w+)="(.*?)"/) do |attr, value|
        value = case value.strip
                when "" then nil
                when /\A\d+\z/ then value.to_i
                when /\A\d+\.\d+\z/ then value.to_f
                else value
                end
        column[attr.to_sym] = value
      end

      result[column.delete(:name)] = column
    end

    result
  end

  def self.build_data(data, metadata)
    columns = []
    rows = []

    data.each do |row_content|
      row = []

      row_content.first.scan(/(\w+)="(.*?)"/) do |attribute, value|
        if value == ''
          value = nil
        else
          value = case metadata[attribute][:type]
                  when 'string' then value.to_s
                  when 'int32', 'int64' then value.to_i
                  else value
                  end
        end
        columns << attribute
        row << value
      end

      rows << row
    end

    { columns: columns.uniq, data: rows }
  end

  def self.custom_to_json(object)
    case object
    when Hash
      hash_to_json(object)
    when Array
      array_to_json(object)
    when String
      "\"#{escape_string(object)}\""
    when Integer, Float
      object.to_s
    when NilClass
      "null"
    else
      raise "Unsupported data type: #{object.class}"
    end
  end

  def self.hash_to_json(hash)
    pairs = hash.map { |key, value| "\"#{key}\": #{custom_to_json(value)}" }
    "{#{pairs.join(', ')}}"
  end

  def self.array_to_json(array)
    elements = array.map { |element| custom_to_json(element) }
    "[#{elements.join(', ')}]"
  end

  def self.escape_string(str)
    str.gsub(/["\\]/) { |c| "\\#{c}" }
  end

end
