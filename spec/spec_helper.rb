require 'dee_bee/helpers'
require 'dee_bee/configuration'
require 'dee_bee/backup'
require 'dee_bee/file_rotation'
require 'dee_bee/cloud_sync'
require 'timecop'
require 'mocha/api'
require 'fakefs/safe'

Fog.mock!