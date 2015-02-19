#!/usr/bin/env ruby
require 'fileutils'

require 'term/ansicolor'
include Term::ANSIColor

module DeeBee
  module Helpers
    ONE_MONTH = 60 * 60 * 24 * 30

    # Delete files orphaned on the remote after 30 days
    DEFAULT_DAYS_TO_KEEP_ORPHANS = 30

    def run_command (command)
      stdin, stdout, stderr = Open3.popen3(command)
      errors = stderr.readlines
      unless errors.empty?
        raise "Command failed with errors: \n#{errors.join("\n")}"
      end
    end

    def symbolize_keys(original_hash)
      original_hash.inject({}) do |acc, (k,v)|
        key = String === k ? k.to_sym : k
        value = Hash === v ? v.symbolize_keys : v
        acc[key] = value
        acc
      end
    end

    def copy_files_of_pattern_to_directoy (opts)
      files = Dir.glob("#{opts[:directory]}/#{opts[:pattern]}").select { |fn| File.file?(fn) }

      # make the destination directory
      FileUtils.mkdir_p(opts[:new_directory]) unless File.directory? opts[:new_directory]

      files.each do |project_file|
        new_filepath = File.join([opts[:new_directory], File.basename(project_file)])
        if !!opts[:pretend]
          puts "  pretend: cp #{project_file}, #{new_filepath}" unless File.exists?(new_filepath)
        else
          unless File.exists?(new_filepath)
            FileUtils.cp(project_file, new_filepath)
            puts "  cp #{project_file}, #{new_filepath}" #NOTE: don't use verbose in FileUtils with FakeFS
          end
          FileUtils.rm(project_file) if opts[:remove_original]
        end
      end
    end

    def move_files_of_pattern_to_directoy (opts)
      copy_files_of_pattern_to_directoy (opts.merge(:remove_original => true))
    end

    def remove_files_not_containing_substrings (opts)
      substrings = opts[:substrings].is_a?(String) ? [opts[:substrings]] : opts[:substrings]
      files = Dir.glob("#{opts[:directory]}/**/*").select { |fn| File.file?(fn) }

      files.each do |filename|
        unless substrings.any?{ |substring| File.basename(filename) =~ /#{substring}/ }
          if !!opts[:pretend]
            puts "pretend: rm #{filename}"
          else
            FileUtils.rm(filename)
            puts "  rm #{filename}"
          end
        end
      end
    end

    def age_in_days (timestamp)
      ((Time.now - timestamp)/60/60/24).floor
    end

    def time_elapsed_for(name)
      start_time = Time.now
      result = yield
      elapsed_time = Time.now - start_time
      print green, "#{name} completed in #{ "%0.2f" % elapsed_time } seconds", reset, "\n"
      result
    end
  end
end
