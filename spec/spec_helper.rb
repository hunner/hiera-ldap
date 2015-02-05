TEST_LDIF_FILE = 'spec/fixtures/testing.ldif'
TEST_HIERA_CONF = 'spec/fixtures/test-hiera.yaml'

require 'rspec'
require 'ladle'
require 'hiera'
require 'hiera/config'

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift(File.join(PROJECT_ROOT, "lib"))

RSpec.configure do |config|
  config.mock_with :mocha
end
