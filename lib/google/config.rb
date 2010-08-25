module Google
  class Config
    CONFIG = YAML.load_file(File.join(Rails.root, "config", "google.yml"))

    def self.setting(name)
      CONFIG[name]
    end
  end
end
