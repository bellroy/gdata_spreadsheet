require 'google/config'

module Google
  WORKSHEET_BASE_URL = "https://spreadsheets.google.com/feeds/worksheets"
  LIST_BASE_URL = "https://spreadsheets.google.com/feeds/list"

  class MissingDocumentError < ::Exception
  end

  class FatalError < ::Exception
  end

  # Interface to the GData API.
  #
  # You shouldn't have to use this class in your code, except when debugging!
  class Spreadsheet

    def initialize(key)
      @key = key
    end

    def row_data(field, value, worksheet_id = 1)
      request_with_error_handling(:get, :list, "#{LIST_BASE_URL}/#{@key}/#{worksheet_id}/private/full?sq=#{CGI.escape(field)}=#{CGI.escape(value)}") do |response|
        xml = Nokogiri::XML.parse(response.body)
        xml.css('entry').first
      end
    end

    def update_row(xml, worksheet_id = 1)
      request_with_error_handling :put, :list, xml.css("link[rel = edit]").first["href"], xml.to_xml
    end

    def add_row(xml, worksheet_id = 1)
      request_with_error_handling :post, :list, "#{LIST_BASE_URL}/#{@key}/#{worksheet_id}/private/full", xml.to_xml
    end

    def worksheet_id_for(name)
      request_with_error_handling(:get, :worksheet, "#{WORKSHEET_BASE_URL}/#{@key}/private/full") do |response|
        xml = Nokogiri::XML.parse(response.body)

        # translate converts the attribute's content to lower case,
        # therefore allowing us to match case-insensitive
        xml.xpath(".//atom:entry[translate(
            atom:title,
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
            'abcdefghijklmnopqrstuvwxyz'
          ) = '#{name.downcase}']/atom:id",
          "atom" => "http://www.w3.org/2005/Atom"
        ).text.split("/").last
      end
    end

  protected

    def client(type)
      client = GData::Client::Spreadsheets.new(:version => '3', :source => 'PlanDeliver')
      client.authsub_token = Config.setting("#{type}_token")
      client
    end

    def request_with_error_handling(method, token_type = "list", *args)
      response = client(token_type).send(method, *args)
      yield(response) if block_given?
    rescue GData::Client::RequestError => e
      raise Google::FatalError.new(e.message)
    end
  end
end
