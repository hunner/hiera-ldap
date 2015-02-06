require 'spec_helper'
require 'hiera/backend/ldap_backend'

class Hiera
  module Backend
    describe Ldap_backend do

      before do
        Hiera::Config.load(TEST_HIERA_CONF)
        Hiera.stubs(:debug)
        Hiera.stubs(:warn)
        Hiera::Backend.stubs(:empty_answer).returns(nil)
      end

      before(:all) do
        @ldap_server = Ladle::Server.new(
          :tmpdir => '/tmp',
          :quiet => true, #Comment this out for LDAP debuging
          :port => 3897,
          :domain => 'dc=example,dc=org',
          :ldif => TEST_LDIF_FILE
        ).start
      end

      after(:all) do
        @ldap_server.stop if @ldap_server
      end

      describe "#initialize" do
        it "should announce its creation" do
          Hiera.expects(:debug).with("Hiera LDAP backend starting")

          Net::LDAP.expects(:new).with(
            :host => 'localhost',
            :port => 3897,
            :auth => {
              :method => :simple,
              :username => 'cn=Alexandra Adams,ou=bar,dc=living,dc=com',
              :password => 'smada',
            },
            :base => 'dc=example,dc=org',
            :encryption => nil,
          )

          Ldap_backend.new()
        end
      end

    end
  end
end
