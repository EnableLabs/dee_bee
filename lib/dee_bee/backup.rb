require 'open3'

module DeeBee
  class Backup
    include DeeBee::Helpers

    attr_reader :backup_settings

    def initialize (configuration = DeeBee::Configuration.new)
      @backup_settings = configuration.settings['backup']
    end

    def execute
      puts "\nCreating backup..."
      time_elapsed_for("Create backup") do
        if performing_mysql_backup?
          validate_my_cnf_present
          validate_host_setting_present
          validate_database_name_setting_present
          validate_path_exists

          # NOTE - no use of -u or -p as we are using ~/.my.cnf for these arguments
          run_command("/usr/bin/env mysqldump -h#{backup_settings['database']['host']} #{backup_settings['database']['database_name']} | gzip > #{backup_filepath}")

          validate_mysqldump_created_file
        else
          raise "Unknown/empty database adapter.  Please correct your settings yaml"
        end
      end
    end

    private

    def performing_mysql_backup?
      backup_settings['database']['provider'].downcase =~ /mysql/
    end

    def validate_my_cnf_present
      raise "~/.my.cnf file not found.  Please create and define user and password arguments" unless File.exists?( File.expand_path("~/.my.cnf") )
    end

    def validate_host_setting_present
      raise "database host not defined in setting yaml file" if backup_settings['database']['host'].nil?
    end

    def validate_database_name_setting_present
      raise "database name not defined in setting yaml file" if backup_settings['database']['database_name'].nil?
    end

    def validate_path_exists
      directories = backup_filepath.split(File::SEPARATOR).map{ |directory| directory.empty? ? nil : directory }.compact[0..-2]
      (0..(directories.size-1)).each do |index|
        directory = "#{File::SEPARATOR}#{directories[0..index].join(File::SEPARATOR)}"
        raise "Directory does not exist => #{directory}" unless File.exists?(directory)
      end
    end

    def backup_filepath
      if @backup_filepath.nil?
        directory = backup_settings['directory']
        file_prefix =  backup_settings['file_prefix']
        @backup_filepath = File.join(directory, "#{file_prefix}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.sql.gz")
      end

      @backup_filepath
    end

    def validate_mysqldump_created_file
      if File.exists?(backup_filepath)
        puts "  created #{backup_filepath}"
      else
        raise "Backup did not create file!"  
      end
    end
  end
end
