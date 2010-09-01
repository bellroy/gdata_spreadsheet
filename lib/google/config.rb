require 'yaml'

module Google

  # Wrapper to access settings.
  # Unless you specify additional settings in your config file,
  # you should never have to call settings on your own!
  #
  # === Initialisation
  #
  #   Google::Config.file = File.join(File.dirname(__FILE__), "google.yml")
  #
  # === Example
  #
  #   account:          account@google.com
  #   worksheet_token:  session_token_for_worksheets
  #   list_token:       session_token_for_lists
  class Config
    def self.file=(path)
      @@file = path
    end

    def self.setting(name)
      @@yaml ||= YAML.load_file(@@file)
      @@yaml[name]
    end
  end
end
