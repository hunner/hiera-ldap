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
        answer = nil

        Hiera.debug("Looking up #{key} in LDAP backend")

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")
          conf = Config[:ldap]
          base = conf[:base]
          Hiera.debug("Searching on base: #{base}")

          begin
            filterstr = "(&(objectClass=puppetClient)(cn=#{source}))"
            filter = Net::LDAP::Filter.from_rfc4515(filterstr)
            treebase = conf[:base]
            searchresult = @connection.search(:filter => filter)

            answer = []

            searchresult.each do |entry|
              if entry["#{@searchattr}"]
                Hiera.debug("Entry #{entry['cn']} has key #{@searchattr}: #{entry[@searchattr]}")
                # Now we do have hiera data, let's see if the key we're looking for is here.
                if entry[@searchattr].is_a? String
                  # First turn string into single-value arrays.
                  entry[@searchattr] = [entry[@searchattr]]
                end
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

                  end
                end
              end
            end
          end
          return answer unless answer == []
        end
      rescue Exception => e
            Hiera.debug("Exception: #{e}")
      end
    end
  end
end
