require 'rubygems'
require 'net/ldap'

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

class Hiera
  module Backend
    class Ldap_backend
      def initialize
        conf = Config[:ldap]
        @base = conf[:base]

        Hiera.debug("Hiera LDAP backend starting")

        @connection = Net::LDAP.new(
          :host       => conf[:host],
          :port       => conf[:port],
          :auth       => conf[:auth],
          :base       => conf[:base],
          :encryption => conf[:encryption])
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up #{key} in LDAP backend")

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")
          conf = Config[:ldap]
          base = conf[:base]
          Hiera.debug("Searching on base: #{base}")

          answer = []

          begin
            filter = Net::LDAP::Filter.from_rfc4515(key)
            treebase = conf[:base]
            searchresult = @connection.search(:filter => filter, :attributes => conf[:attributes])

            for i in 0..searchresult.length-1 do
              answer[i] = {}
              searchresult[i].each do |attribute, values|
                Hiera.debug( "   #{attribute}:")
                answer[i][attribute.to_s] = values
                values.each do |value|
                  Hiera.debug( "   ---->#{value}:")
                 end
              end
            end
          rescue Exception => e
            Hiera.debug("Exception: #{e}")
          end
          Hiera.debug(answer)

        end

        return answer unless answer == []
      end
    end
  end
end
