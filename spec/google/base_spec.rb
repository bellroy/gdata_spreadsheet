require 'spec_helper'

class TestOrder < Google::Base

  def worksheet_name
    "sync log"
  end

  def id_column
    "id"
  end
end

describe Google::Base do

  before do
    Google::Spreadsheet.stub! :new => @sheet = mock("Spreadsheet")

    @sheet.stub! :worksheet_id_for => "test",
                 :row_data => Nokogiri::XML.parse("<entry><id>1</id></entry>").css("entry").first
  end

  describe "initialize" do
    it "should return a new document, if we didn't specify a id_column" do
      class TestOrder
        def id_column; nil end
      end

      TestOrder.new(1, 2).should be_new_record
    end

    it "should return a new document if we cant find a matching row in the spreadsheet" do
      @sheet.stub! :row_data => nil
      TestOrder.new(1, 2).should be_new_record
    end

    it "should initialize the returned doc if a matching row in the spreadsheet has been found" do
      order = TestOrder.new(1, 2)
      order.should_not be_new_record
      order.doc["xmlns"].should == "http://www.w3.org/2005/Atom"
    end
  end
end
