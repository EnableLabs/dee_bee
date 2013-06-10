require 'optparse'

module DeeBee
  module Command
    class << self
      def options
        @options ||= parse_options
      end

      def run
        if options.empty?
          print red, "Dee Bee needs some work to do, please specify an operation parameter.", reset, "\n"
          exit
        end

        configuration = DeeBee::Configuration.new(options[:settings_yaml])

        print yellow, "\nDee Bee buzzing at #{Time.now}", reset, "\n"

        if !!options[:perform_backup]
          DeeBee::Backup.new(configuration).execute
        end
        
        if !!options[:perform_rotation]
          DeeBee::FileRotation.new(configuration).execute
        end

        if !!options[:perform_cloud_sync]
          DeeBee::CloudSync.new(configuration).execute
        end

        if !!options[:perform_all]
          DeeBee::Backup.new(configuration).execute
          DeeBee::FileRotation.new(configuration).execute
          DeeBee::CloudSync.new(configuration).execute
        end
      end

      private

      def parse_options
        # Parse Options
        options = {}
        opt_parser = OptionParser.new do |opt|
          opt.banner = "Usage: #{$0} [OPTIONS]"
          opt.separator  ""
          opt.separator  "Options"

          opt.on("-s","--settings <filename>","use specific yaml file") do |settings_yaml|
            options[:settings_yaml] = settings_yaml
          end

          opt.on("-b","--backup","performa backup") do
            options[:perform_backup] = true
          end

          opt.on("-r","--rotation","performa rotation") do
            options[:perform_rotation] = true
          end

          opt.on("-c","--cloud-sync","performa cloud sync") do
            options[:perform_cloud_sync] = true
          end

          opt.on("-a","--all","performa backup, rotation, and sync") do
            options[:perform_all] = true
          end
        end
        opt_parser.parse!
        return options
      end
    end
  end
end