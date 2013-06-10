module DeeBee
  class FileRotation
    include DeeBee::Helpers

    attr_reader :directory, :file_prefix

    def initialize (configuration = DeeBee::Configuration.new)
      @directory =  configuration.settings['file_rotation']['directory']
      @file_prefix =  configuration.settings['file_rotation']['file_prefix']
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
          :substrings => (0..6).collect{ |days_ago| (Date.today - days_ago).strftime("%Y%m%d_") }
      end
    end

    private

    def validate_settings
      raise "File Rotation Failed: 'directory' setting not found" unless !!directory
      raise "File Rotation Failed: 'file_prefix' setting not found" unless !!file_prefix
    end
  end    
end
