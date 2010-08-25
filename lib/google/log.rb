module Google
  class Log < Base

    def initialize(doc_id, message)
      super doc_id

      @message = message
      new_row
    end

    def worksheet_name
      "sync log"
    end

    def sync_attributes
      {
        :timestamp  => Time.now.to_s(:db),
        :message    => @message
      }
    end
  end
end
