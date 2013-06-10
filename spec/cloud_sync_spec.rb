require 'spec_helper.rb'
require 'fileutils'

describe DeeBee::CloudSync do
  describe '#execute' do
    describe 'given settings for cloud sync' do
      let(:mock_configuration) do
        mock('MockDeeBeeConfiguration').tap do |m|
          m.stubs(:settings).returns({
            'cloud_sync' => {
              'local_directory' => '/tmp/backups',
              'credentials' => {
                'provider'   => 'aws',
                'aws_access_key_id' => 'XXXXXXXXXXXXXXXXXXXX',
                'aws_secret_access_key' => 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
              },
              'provider_settings' => {
                'remote_storage' => 'production.backups'
              }
            }
          })
        end
      end

      let(:cloud_sync) do
        DeeBee::CloudSync.new(mock_configuration)
      end

      before(:each) do
        Timecop.freeze( Time.local(2013, 6, 6, 13, 0, 0) )
        FakeFS.activate!
        FakeFS::FileSystem.clear
      end

      after(:each) do
        Timecop.return
        FakeFS::FileSystem.clear
        FakeFS.deactivate!
      end

      it "should sync local files to the remote directory" do
        Dir.glob("/**/*").should be_empty

        FileUtils.mkdir '/tmp'
        FileUtils.mkdir '/tmp/backups'
        FileUtils.mkdir '/tmp/backups/daily'        
        FileUtils.touch('/tmp/backups/daily/test_project_20130529_120000.sql.gz')
        FileUtils.touch('/tmp/backups/daily/test_project_20130530_120000.sql.gz')
        FileUtils.touch('/tmp/backups/daily/test_project_20130531_120000.sql.gz')
        FileUtils.touch('/tmp/backups/daily/test_project_20130601_120000.sql.gz')
        FileUtils.touch('/tmp/backups/daily/test_project_20130602_120000.sql.gz')
        FileUtils.touch('/tmp/backups/daily/test_project_20130603_120000.sql.gz')
        FileUtils.touch('/tmp/backups/daily/test_project_20130604_120000.sql.gz')
        FileUtils.mkdir '/tmp/backups/monthly'
        FileUtils.touch('/tmp/backups/monthly/test_project_20130401_120000.sql.gz')
        FileUtils.touch('/tmp/backups/monthly/test_project_20130501_120000.sql.gz')
        FileUtils.touch('/tmp/backups/monthly/test_project_20130601_120000.sql.gz')

        cloud_sync.execute

        extend DeeBee::Helpers
        fog = Fog::Storage.new( symbolize_keys(mock_configuration.settings['cloud_sync']['credentials']) )
        fog.directories.create(:key => mock_configuration.settings['cloud_sync']['provider_settings']['remote_storage'])
        remote_directory = fog.directories.get( mock_configuration.settings['cloud_sync']['provider_settings']['remote_storage'] )
        remote_keys = remote_directory.files.collect{|remote_object| remote_object.key }
        remote_keys.should eq [
          "daily/",
          "daily/test_project_20130529_120000.sql.gz",
          "daily/test_project_20130530_120000.sql.gz",
          "daily/test_project_20130531_120000.sql.gz",
          "daily/test_project_20130601_120000.sql.gz",
          "daily/test_project_20130602_120000.sql.gz",
          "daily/test_project_20130603_120000.sql.gz",
          "daily/test_project_20130604_120000.sql.gz",
          "monthly/",
          "monthly/test_project_20130401_120000.sql.gz",
          "monthly/test_project_20130501_120000.sql.gz",
          "monthly/test_project_20130601_120000.sql.gz"
        ]
      end
    end
  end
end
