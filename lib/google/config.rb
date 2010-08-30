require 'yaml'

module Google
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
