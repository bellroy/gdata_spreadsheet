module Google

  # Base class for all your spreadsheet models.
  # Check the Readme for detailed information on how it's used.
  #
  # === Finding / updating existing records
  #
  #   order = Google::Order.new("spreadsheet_id", "1234")
  #   order.save
  #
  # === Creating new records
  #
  #   order = Google::Order.new("spreadsheet_id")
  #   order.sync!
  class Base
    attr_reader :doc

    # The standard initialiser takes the spreadsheet ID and an optional record ID
    # (check the Readme to see how records are mapped). Overwrite the initialiser
    # in order to pass in other necessary information (eg. as in Log).
    #
    # If a record ID is specified, then the associated row from the spreadsheet will be fetched,
    # otherwise a new record is build.
    def initialize(doc_id, row_id = nil)
      raise Google::MissingDocumentError unless doc_id

      @sheet = Spreadsheet.new(doc_id)
      @worksheet_id = @sheet.worksheet_id_for(worksheet_name)

      initialize_row row_id
    end

    # Creates or updates the record.
    def save
      if new_record?
        @sheet.add_row @doc, @worksheet_id
      else
        @sheet.update_row @doc, @worksheet_id
      end
    end

    # Returns true if the record is not yet pushed to the spreadsheet.
    def new_record?
      !@doc.css("id").first
    end

    # Name of the worksheet that's mapped to the model.
    #
    # Overwrite this in your sub-class!
    def worksheet_name
      raise "Abstract! Overwrite this method in your subclass"
    end

    # Name of the column that'll will be used as the ID column.
    #
    # Overwrite this in your sub-class!
    #
    # <tt>return nil</tt> in your subclass, if you want a push only model
    def id_column
      raise "Abstract! Overwrite this method in your subclass"
    end

    # specify how attributes are mapped to the spreadsheet.
    #
    # ==== Example
    #   {
    #     :timestamp  => Time.now.to_s(:db),
    #     :message    => @message
    #   }
    #
    # The keys in the hash represent columns in the spreadsheet
    # (check out the Readme, for more information about attribute mapping), the values will
    # be written to the cells.
    def sync_attributes
      { }
    end

    # Maps all attributes specified in Base#sync_attributes, so that a subsequent Base#save
    # will push the data to the spreadsheet columns.
    def sync
      sync_attributes.each do |field, value|
        set field, value
      end
    end

    # Convenience method with executes Base#sync and then Base#save.
    def sync!
      sync
      save
    end

  protected

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
