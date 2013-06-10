require 'spec_helper.rb'
require 'fileutils'

describe DeeBee::FileRotation do
  describe '#execute' do
    describe 'given settings for file rotation' do
      let(:mock_configuration) do
        mock('MockDeeBeeConfiguration').tap do |m|
          m.stubs(:settings).returns({
            'file_rotation' => {
              'directory'   => '/tmp/backups',
              'file_prefix' => 'test_project',
              'days_to_keep_daily_files' => 7
            }
          })
        end
      end

      let(:file_rotation) do
        DeeBee::FileRotation.new(mock_configuration)
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

      it "should rotate files in the base directory into daily and monthly subdirectories" do
        Dir.glob("/**/*").should be_empty

        FileUtils.mkdir '/tmp'
        FileUtils.mkdir '/tmp/backups'
        FileUtils.touch('/tmp/backups/test_project_20130527_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130528_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130529_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130530_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130531_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130601_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130602_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130603_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130604_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130605_120000.sql.gz')
        FileUtils.touch('/tmp/backups/test_project_20130606_120000.sql.gz')

        file_rotation.execute

        files = Dir.glob("/**/*")
        files.size.should eq 12
        files.should include("/tmp")
        files.should include("/tmp/backups")
        files.should include("/tmp/backups/monthly")
        files.should include("/tmp/backups/monthly/test_project_20130601_120000.sql.gz")
        files.should include("/tmp/backups/daily")
        files.should include("/tmp/backups/daily/test_project_20130531_120000.sql.gz")
        files.should include("/tmp/backups/daily/test_project_20130601_120000.sql.gz")
        files.should include("/tmp/backups/daily/test_project_20130602_120000.sql.gz")
        files.should include("/tmp/backups/daily/test_project_20130603_120000.sql.gz")
        files.should include("/tmp/backups/daily/test_project_20130604_120000.sql.gz")
        files.should include("/tmp/backups/daily/test_project_20130605_120000.sql.gz")
        files.should include("/tmp/backups/daily/test_project_20130606_120000.sql.gz")
      end
    end
  end
end




