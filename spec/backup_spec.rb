require 'spec_helper.rb'

describe DeeBee::Backup do
  describe '#execute' do
    describe 'given settings for a mysql database' do
      let(:mock_configuration) do
        mock('MockDeeBeeConfiguration').tap do |m|
          m.stubs(:settings).returns({
           'backup' => {
              'directory'   => '/tmp/backups',
              'file_prefix' => 'test_project' , 
              'database'    => {
                'provider'      => 'mysql',
                'host'          => 'localhost',
                'database_name' => 'test_database'
              }
            }
          })
        end
      end

      let(:backup) do
        DeeBee::Backup.new(mock_configuration)
      end

      it "should system call a proper mysqldump command" do
        backup.expects(:validate_my_cnf_present).returns(nil)

        Timecop.freeze( Time.local(2013, 6, 3, 12, 0, 0) )

        backup.expects("run_command").with("/usr/bin/env mysqldump -hlocalhost test_database | gzip > /tmp/backups/test_project_20130603_120000.sql.gz").returns(nil)
        backup.expects(:validate_mysqldump_created_file).returns(nil)

        backup.execute

        Timecop.return
      end
    end
  end
end
