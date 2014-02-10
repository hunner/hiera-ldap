require 'rubygems'
require 'net/ldap'
require 'json'

# Monkey patch Net::LDAP::Connection to ensure SSL certs aren't verified
class Net::LDAP::Connection
  def self.wrap_with_ssl(io)
    raise Net::LDAP::LdapError, "OpenSSL is unavailable" unless Net::LDAP::HasOpenSSL
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
    conn = OpenSSL::SSL::SSLSocket.new(io, ctx)
    conn.connect
    conn.sync_close = true

    conn.extend(GetbyteForSSLSocket) unless conn.respond_to?(:getbyte)

    conn
  end
end

class String
  def valid_json?
    begin
      JSON.parse(self)
      return true
    rescue JSON::ParserError
      return false
    end
  end
end

class Hiera
  module Backend
    class Ldap_backend
      def initialize
        conf = Config[:ldap]
        @base = conf[:base]

        Hiera.debug("Hiera LDAP backend starting")
        @searchattr = get_config_value(:attribute, "puppetVar")
        @connection = Net::LDAP.new(
          :host       => conf[:host],
          :port       => get_config_value(:port, "389"),
          :auth       => conf[:auth],
          :base       => conf[:base],
          :encryption => conf[:encryption])
      end

      # Helper for parsing config. Does not Hiera provide one?
      def get_config_value(label, default)
        if Config.include?(:ldap) && Config[:ldap].include?(label)
          Config[:ldap][label]
        else
          default
        end
      end


      def lookup(key, scope, order_override, resolution_type)
        conf = Config[:ldap] 

        # Testing if the key is an arbitrary LDAP Search key
        if key.split('')[0] == '(' and key.split('')[key.length-1] == ')'
          answer = []
          filter = Net::LDAP::Filter.from_rfc4515(key)
          treebase = conf[:base]
          Hiera.debug("Searching #{key} in LDAP backend, base #{treebase}.")
          searchresult = @connection.search(:filter => filter)

          for i in 0..searchresult.length-1 do
            answer[i] = {}
            searchresult[i].each do |attribute, values|
              Hiera.debug( " #{attribute}:")
              answer[i][attribute.to_s] = values
              values.each do |value|
                Hiera.debug( " ---->#{value}:")
              end
            end
          end
	  return answer unless answer == []
        
        # "Key" is an ordinary puppet variable
        else
          answer = []
          Hiera.debug("Looking up #{key} in LDAP backend")

          Backend.datasources(scope, order_override) do |source|
            Hiera.debug("Looking for data source #{source}")
            base = conf[:base]
            Hiera.debug("Searching on base: #{base}")
            begin
              filterstr = "(&(objectClass=puppetClient)(cn=#{source}))"
              filter = Net::LDAP::Filter.from_rfc4515(filterstr)
              treebase = conf[:base]
              searchresult = @connection.search(:filter => filter)


              searchresult.each do |entry|
                if entry[@searchattr] != []
                  Hiera.debug("Entry #{entry['cn']} has key #{@searchattr}: '#{entry[@searchattr]}'")
                  # Now we do have hiera data, let's see if the key we're looking for is here.
                  entry[@searchattr].each do |line|
                    k, v = line.split "=", 2
                    if k == key
                      # Verify if boolean
                      if v == "true"
                        v = true
                      end
                      if v == "false"
                        v = false
                      end

                      # Parse JSON
                      if v.valid_json?
	                v = JSON.parse(v)
                      end
                    
  		      # Construct response
                      if answer
                        if answer.is_a? String
                          answer = [answer, v]
                        else
                          answer.push v
                        end
                      else
                        answer = v
                      end
                    end #end if k == key
                  end #end entry[@searchattr].each
                end #end if entry[@searchattr] != []

                if answer == [] 
                   k = key.rpartition("::").last 
                   Hiera.debug("Entry #{key} not found in #{@searchattr} key. Looking up for key #{k}.")
                   entry[k].each do |line|
                     # Construct response
                     if answer
                       if answer.is_a? String
                         answer = [answer, line]
                       else
                         answer.push line
                       end
                     else
                       answer = line
                     end
                     Hiera.debug("Found LDAP key #{k} with value: #{line}.")
                   end
                end

              end #end searchresult.each
            end #end datasources begin
          end #end datasources
          return answer unless answer == []
        end #end else
      rescue Exception => e
            Hiera.debug("Exception: #{e}")
      end
    end
  end
end
