module Google

  # Example spreadsheet model.
  #
  # This enables very basic message pushing to a spreadsheet named 'sync log'
  #
  # === Usage
  #
  #   entry = Google::Log.new("spreadsheet_id", "awesome stuff!")
  #   entry.sync!
  class Log < Base

    def initialize(doc_id, message)
      super doc_id

      @message = message
    end

  private

    def worksheet_name
      "sync log"
    end

    def id_column
      nil
    end

    def sync_attributes
      {
        :timestamp  => Time.now.to_s(:db),
        :message    => @message
      }
    end
  end
end
