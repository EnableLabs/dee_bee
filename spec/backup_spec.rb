require 'spec_helper.rb'

describe DeeBee::Backup do
  describe '#execute' do
    describe 'given settings for a mysql database' do
      let(:mock_configuration) do
        double('MockDeeBeeConfiguration').tap do |m|
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
        backup.expects(:validate_path_exists).returns(nil)

        backup.execute

        Timecop.return
      end

      it "should validate ~/.my.cnf is present" do
        File.expects(:exists?).returns(false)
        expect { backup.execute }.to raise_error("~/.my.cnf file not found.  Please create and define user and password arguments")
      end

      it "should validate host_setting_present" do
        backup.expects(:validate_my_cnf_present).returns(nil)
        backup.expects(:database_host).returns(nil)
        expect { backup.execute }.to raise_error("database host not defined in setting yaml file")
      end

      it "should validate_database_name_setting_present" do
        backup.expects(:validate_my_cnf_present).returns(nil)
        backup.expects(:validate_host_setting_present).returns(nil)
        backup.expects(:database_name).returns(nil)
        expect { backup.execute }.to raise_error("database name not defined in setting yaml file")
      end

      it "should validate_mysqldump_created_file" do
        backup.expects(:validate_my_cnf_present).returns(nil)

        Timecop.freeze( Time.local(2013, 6, 3, 12, 0, 0) )

        file_name = "/tmp/backups/test_project_20130603_120000.sql.gz"

        backup.expects("run_command").with("/usr/bin/env mysqldump -hlocalhost test_database | gzip > #{file_name}").returns(nil)
        backup.expects(:validate_path_exists).returns(nil)

        expect do
          File.expects(:exists?).with(file_name).returns false
          backup.execute
        end.to raise_error("Backup did not create file!" )

        Timecop.return
      end
    end
  end
end
