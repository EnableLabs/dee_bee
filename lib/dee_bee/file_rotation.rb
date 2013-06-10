module DeeBee
  class FileRotation
    include DeeBee::Helpers

    DEFAULT_DAYS_TO_KEEP_DAILY_FILES = 7

    attr_reader :directory, :file_prefix, :days_to_keep_daily_files

    def initialize (configuration = DeeBee::Configuration.new)
      @directory =  configuration.settings['file_rotation']['directory']
      @file_prefix =  configuration.settings['file_rotation']['file_prefix']
      @days_to_keep_daily_files = configuration.settings['file_rotation']['days_to_keep_daily_files']
    end

    def execute
      validate_settings

      puts "\nRotating files..."
      time_elapsed_for("Rotate files") do
        puts "  Copy monthly files into /monthly"
        copy_files_of_pattern_to_directoy :directory => directory,
          :pattern        => "#{file_prefix}*[0-9][0-9][0-9][0-9][0-9][0-9]01_[0-9][0-9][0-9][0-9][0-9][0-9].sql.gz",
          :new_directory => File.join([directory, 'monthly'])

        puts "  Copy all files into /daily"
        move_files_of_pattern_to_directoy :directory => directory,
          :pattern       => "#{file_prefix}*.sql.gz",
          :new_directory => File.join([directory, 'daily'])

        puts "  Remove /daily files older than 7 days"
        remove_files_not_containing_substrings :directory => File.join([directory, 'daily']),
          :substrings => substrings_for_files_to_keep
      end
    end

    private

    def validate_settings
      raise "File Rotation Failed: 'directory' setting not found" unless !!directory
      raise "File Rotation Failed: 'file_prefix' setting not found" unless !!file_prefix
    end

    def substrings_for_files_to_keep
      (0..((days_to_keep_daily_files || DEFAULT_DAYS_TO_KEEP_DAILY_FILES) - 1)).collect{ |days_ago| (Date.today - days_ago).strftime("%Y%m%d_") }
    end
  end    
end
