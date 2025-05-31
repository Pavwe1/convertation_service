require 'nokogiri'

class XmlConvertService

  def self.call(io)
    handler = SaxHandler.new
    parser = Nokogiri::XML::SAX::Parser.new(handler)
    parser.parse(io)
    custom_to_json(handler.result)
  end

  class SaxHandler < Nokogiri::XML::SAX::Document
    attr_reader :result

    def initialize
      @result = {}
      @current_data_id = nil
      @metadata = {}
      @columns = []
      @rows = []
    end

    def start_element(name, attrs = [])
      attrs_hash = convert_attrs(attrs)

      case name
      when 'data'
        @current_data_id = attrs_hash['id']
        @metadata = {}
        @columns = []
        @rows = []
      when 'column'
        column = parse_attributes(attrs_hash)
        name = column.delete(:name)
        @metadata[name] = column
      when 'row'
        row = []
        attrs_hash.each do |attr, val|
          val = convert(val, @metadata[attr]&.[](:type))
          @columns << attr
          row << val
        end
        @rows << row
      end
    end

    def end_element(name)
      if name == 'data'
        @result[@current_data_id.to_sym] = {
          metadata: @metadata,
          columns: @columns.uniq,
          data: @rows
        }
      end
    end

    def convert_attrs(attrs)
      return Hash[attrs] if attrs.all? { |el| el.is_a?(Array) && el.size == 2 }
      return Hash[attrs.each_slice(2).to_a] if attrs.all? { |el| el.is_a?(String) }
      raise ArgumentError, "Unexpected attributes format: #{attrs.inspect}"
    end

    def parse_attributes(attrs)
      attrs.transform_keys(&:to_sym).transform_values do |val|
        case val.strip
        when "" then nil
        when /\A\d+\z/ then val.to_i
        when /\A\d+\.\d+\z/ then val.to_f
        else val
        end
      end
    end

    def convert(val, type)
      return nil if val == ''
      case type
      when 'string' then val.to_s
      when 'int32', 'int64' then val.to_i
      else val
      end
    end
  end

  private

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
