require 'yaml'

module DeeBee
  class Configuration
    attr_reader :settings

    def initialize (specified_settings_yaml_file)
      @specified_settings_yaml_file = specified_settings_yaml_file
      load_settings
    end

    private

    def load_settings
      @settings = if @specified_settings_yaml_file
          validate_specified_settings_yaml
          YAML.load_file(@specified_settings_yaml_file)
        else
          validate_default_settings_yaml
          YAML.load_file(default_settings_yaml_file)
        end
    end

    def validate_specified_settings_yaml
      unless File.exists?(@specified_settings_yaml_file)
        print red, "Dee Bee cannot locate specified settings yaml file '#{@specified_settings_yaml_file}'", reset, "\n"
        exit -1
      end
    end

    def validate_default_settings_yaml?
      unless File.exists?(default_settings_yaml_file)
        print red, "Dee Bee cannot locate a default settings yaml file '#{default_settings_yaml_file}'", reset, "\n"
        exit -1
      end
    end

    def default_settings_yaml_file
      File.join(Dir.pwd, 'settings.yaml')
    end
  end
end
