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
        @backend = Ldap_backend.new()
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
              :username => 'uid=aa729,ou=people,dc=example,dc=org',
              :password => 'smada',
            },
            :base => 'dc=example,dc=org',
            :encryption => nil,
          )

          Ldap_backend.new()
        end
      end

      describe "#lookup" do
        it "should find values" do
          results = @backend.lookup("cn=Alexandra Adams", {}, nil, :priority)
          results.first["mail"].should eql ['alexandra@example.org']
        end

        it "should return nil if nothing found" do
          results = @backend.lookup("cn=Fakey McFakename", {}, nil, :priority)
          results.should be_nil
        end

        it "should catch errors from LDAP and output them as debug messages" do
          Hiera.expects(:warn).with("Exception: Invalid filter syntax.")
          results = @backend.lookup("[][]", {}, nil, :priority)
        end
      end

    end
  end
end
