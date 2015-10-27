# Dee Bee

Ruby based utilities for database backup, file rotation, and syncing to remote storage.

Remote storage functionality is backed by the [Fog gem](https://github.com/fog/fog) which in turn supports many cloud providers.


## Installation

    $ gem install dee_bee


## Usage

Dee Bee provides a dee_bee executable to be used from the command line.

Specific actions can be programatically called in your Ruby project by utilizing the DeeBee::Configuration, DeeBee::Backup, DeeBee::FileRotation, and DeeBee::CloudSync classes.


### Settings Configuration

Dee Bee requires a settings files in YAML to instruct how backups, rotations, and synchronizations are to be performed.

Your settings yaml file should follow the hash schema as follows:

	name: <usually project name>
	backup:
	  directory:   </path/to/backups>
	  file_prefix: <usually project name>
	  database:
	    provider: mysql
	    host: localhost
	    database_name: <database name>
	file_rotation:
	  directory:   </path/to/backups>
	  file_prefix: <usually project name>
	  days_to_keep_daily_files: 7
	cloud_sync:
	  local_directory: </path/to/backups>
	  credentials:
	    provider:              aws
	    aws_access_key_id:     <key>
	    aws_secret_access_key: <secret>
	  provider_settings:
	    remote_storage: <remote directory or bucket name>
	  long_term_archive:
	    subdirectory: <subdirectory name>
	    rotation_age: <age in days>


### Comand line arguments

Specify a settings yaml file with '--settings':

	$ dee_bee --settings <filename>

A default 'settings.yaml' file will be searched for in the current working directory if '--settings' is not utilized.


Specify specific actions to perform with '--backup', '--rotation', '--cloud-sync'

	$ dee_bee --backup --settings <filename>
	$ dee_bee --rotation --settings <filename>
	$ dee_bee --cloud-sync --settings <filename>

Run all actions:

	$ dee_bee --all --settings <filename>


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Thank you to all [the contributors](https://github.com/EnableLabs/dee_bee/contributors)!
