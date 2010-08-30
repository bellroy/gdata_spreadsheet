module Google
  class Base
    attr_reader :doc

    def initialize(doc_id, row_id = nil)
      raise Google::MissingDocumentError unless doc_id

      @sheet = Spreadsheet.new(doc_id)
      @worksheet_id = @sheet.worksheet_id_for(worksheet_name)

      initialize_row row_id
    end

    def initialize_row(id)
      if id_column && id && @doc = @sheet.row_data(id_column, id.downcase, @worksheet_id)
        initialize_doc
      else
        new_row
      end
    end

    def new_row
      @doc = Nokogiri::XML.parse("<entry xmlns=\"http://www.w3.org/2005/Atom\"></entry>").css("entry").first
      @doc.add_namespace_definition "gsx", "http://schemas.google.com/spreadsheets/2006/extended"
      @doc.add_namespace_definition "gd", "http://schemas.google.com/g/2005"
    end

    def initialize_doc
      @doc["xmlns"] = "http://www.w3.org/2005/Atom"
      @doc["xmlns:gsx"] = "http://schemas.google.com/spreadsheets/2006/extended"
      @doc["xmlns:gd"] = "http://schemas.google.com/g/2005"
    end

    def save
      if new_record?
        @sheet.add_row @doc, @worksheet_id
      else
        @sheet.update_row @doc, @worksheet_id
      end
    end

    def new_record?
      !@doc.css("id").first
    end

    def worksheet_name
      raise "Abstract! Overwrite this method in your subclass"
    end

    def id_column
      raise "Abstract! Overwrite this method in your subclass"
      # return nil in your subclass, if you want a push only model
    end

    def sync_attributes
      { }
    end

    def sync
      sync_attributes.each do |field, value|
        set field, value
      end
    end

    def sync!
      sync
      save
    end

    def method_missing(method, *args, &block)
      method = method.to_s

      if method[-1, 1] == "=" && args.size == 1
        set method[0..-2], *args
      elsif args.empty?
        get method
      else
        raise NoMethodError
      end
    end

  private

    def attribute(field)
      @doc.xpath(".//gsx:#{field}").first
    end

    def get(field)
      attribute(field) && attribute(field).text
    end

    def set(field, value)
      @doc << build_new_attribute(field) unless attribute(field)
      attribute(field).content = value
    end

    def build_new_attribute(field)
      new_attribute = Nokogiri::XML::Node.new(field.to_s, @doc)
      new_attribute.add_namespace_definition "gsx", "http://schemas.google.com/spreadsheets/2006/extended"
      new_attribute.namespace = new_attribute.namespace_definitions.first
      new_attribute
    end
  end
end
