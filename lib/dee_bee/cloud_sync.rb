# Hat Tip: http://urgetopunt.com/rails/s3/cloudfront/2012/03/23/upload-assets-to-s3.html
require 'fog'
require 'digest/md5'

module DeeBee
  class CloudSync
    include DeeBee::Helpers

    class NoHeadError < StandardError
    end

    attr_reader :sync_settings

    def initialize (configuration = DeeBee::Configuration.new)
      @sync_settings =  configuration.settings['cloud_sync']
    end

    def execute
      puts "\nPerforming cloud sync..."
      time_elapsed_for("Cloud sync") do
        local_directory = sync_settings['local_directory']
        puts "  Syncing directory '#{local_directory}'"
        puts "    to provider '#{sync_settings['credentials']['provider']}'"
        puts "    on storage '#{sync_settings['provider_settings']['remote_storage']}'"

        Dir.chdir(local_directory) do
          local_files_metadata = create_local_files_metadata
          raise 'local file list is empty: aborting' unless file_metadata_contains_files?(local_files_metadata)

          remote_storage = get_remote_storage
          remote_directory = get_remote_directory(remote_storage)

          upload_local_files_to_remote_directory(local_files_metadata, remote_directory)
          remove_orphaned_remote_files_older_than(local_files_metadata, remote_directory, 30) #Days
          move_remote_files_to_long_term_storage_directory(remote_storage, local_files_metadata, remote_directory)
          # remote_directory.files.inject([]){ |keys, remote_object| keys << remote_object.key; keys }
        end
      end
    end

    private

    def create_local_files_metadata
      puts "  Creating local file metadata..."
      local_files_metadata = Dir.glob('**/*').inject({}) do |hsh, path|
        if File.directory? path
          hsh.update("#{path}/" => :directory)
        else
          hsh.update(path => Digest::MD5.file(path).hexdigest)
        end
      end
      puts "  done creating metadata at #{Time.now}"
      local_files_metadata
    end

    def file_metadata_contains_files? (file_metadata)
      file_metadata.any?{|path,directory_or_hash| directory_or_hash != :directory}
    end

    def get_remote_storage
      Fog::Storage.new( symbolize_keys(sync_settings['credentials']) )
    end

    def get_remote_directory (remote_storage)
      remote_storage.directories.create(:key => sync_settings['provider_settings']['remote_storage'])
      remote_storage.directories.get( sync_settings['provider_settings']['remote_storage'] )
    end

    def upload_local_files_to_remote_directory (local_files_metadata, remote_directory)
      local_files_metadata.each do |file, etag|
        if etag == :directory
          puts "  Directory #{file}"
          create_directory_on_remote_directory(file, remote_directory)
        elsif identical_file_in_remote_directory?(remote_directory, file, etag)
          puts "  Skipping #{file} (identical)"
        else
          puts "  Uploading #{file}"
          copy_local_file_to_remote_directory(file,remote_directory)
        end
      end
    end

    def remove_orphaned_remote_files_older_than(local_files_metadata, remote_directory, days_old=30)
      puts "\n  Checking orphaned remote files"
      remote_directory.files.each do |remote_object|
        unless local_files_metadata.has_key? remote_object.key
          object_age_in_days = age_in_days(remote_object.last_modified)
          age_text = "day#{ object_age_in_days == 1 ? '' : 's' } old"

          if object_age_in_days > days_old
            puts "  Removing #{remote_object.key} (no longer exists locally, #{object_age_in_days} #{age_text})"
            remote_object.destroy
          else
            puts "  Keeping orphaned remote #{remote_object.key} (#{object_age_in_days} #{age_text})"
          end
        end
      end
    end

    def identical_file_in_remote_directory? (remote_directory, file, etag)
      remote_directory_file_etag(remote_directory, file) == etag
    rescue Excon::Errors::NotFound, NoHeadError
      return false
    end

    def remote_directory_file_etag (remote_directory, file)
      head = remote_directory.files.head(file)
      raise NoHeadError if head.nil?

      head.etag
    end

    def create_directory_on_remote_directory (path, remote_directory)
      # NOTE - empty objects with keys that end in "/" are created to help clients resolve directories
      remote_directory.files.create(
        :key => path,
        :public => false
      )
    end

    def copy_local_file_to_remote_directory (filepath, remote_directory)
      remote_directory.files.create(
        :key => filepath,
        :public => false,
        :body => File.open(filepath),
        :cache_control => "max-age=#{ONE_MONTH}"
      )
    end

    def remote_files_of_remote_directory (remote_directory)
      remote_directory.files.map{ |file| file }
    end

    def move_remote_files_to_long_term_storage_directory (remote_storage, local_files_metadata, remote_directory)
      return unless !!sync_settings['long_term_archive']

      remote_long_term_storage_directory = sync_settings['long_term_archive']['subdirectory']

      puts "\n  Moving remote files to long term storage directory"
      remote_directory.files.each do |remote_object|
        if !remote_object.content_length.zero? && remote_object.key !~ /^#{remote_long_term_storage_directory}\//
          object_age_in_days = age_in_days(remote_object.last_modified)
          if object_age_in_days > sync_settings['long_term_archive']['rotation_age']
            age_text = "day#{ object_age_in_days == 1 ? '' : 's' } old"
            puts "  Moving #{remote_object.key} to long term storage (#{object_age_in_days} #{age_text})"
            remote_storage.copy_object(
              sync_settings['provider_settings']['remote_storage'],
              remote_object.key,
              sync_settings['provider_settings']['remote_storage'],
              "#{remote_long_term_storage_directory}/#{remote_object.key}"
            )
            remote_object.destroy

            if local_files_metadata.has_key?(remote_object.key)
              File.unlink(File.join(sync_settings['local_directory'], remote_object.key))
            end
          end
        end
      end
    end
  end
end