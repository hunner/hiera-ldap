class Hiera
  module Backend
    class Ldap_backend
      def initialize
        require 'ldap'

        Hiera.debug("Hiera LDAP backend starting")
        auth = {
          :method => :simple,
          :username => 'uid=network,ou=Netgroup,dc=catnip',
          :password => 'sedLdapPassword'
        }
        @connection = Net::LDAP.open(:host => 'ldap.cat.pdx.edu', :port => 636, :auth => auth, :encryption => :simple_tls)
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = Backend.empty_answer(resolution_type)

        Hiera.debug("Looking up #{key} in LDAP backend")

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")

          jsonfile = Backend.datafile(:json, scope, source, "json") || next

          data = JSON.parse(File.read(jsonfile))
          puppetclasses = []
          puppetvars = {}

          next if data.empty?
          next unless data.include?(key)

          #dc=afilias-int.info/dc=tor/cn=cctld1.tor.afilias-int.info
          source = source.split('/').reverse

          filter_attribute = source[0].split('=')
          path = source[1,-1]
          filter = Net::LDAP::Filter.eq(filter_attribute[0],filter_attribute[1])
          attrs = ["puppetvars","hieravars"]

          ldap.search(:base => [path,Config[backend][:base]].flatten.join(','), :filter => filter, :attributes => attrs) do |entry|
            Array(*entry["puppetvars"]).each do |puppetvar|
              begin
                value = eval puppetvar
                value << host unless host == ""
              rescue SyntaxError => e
                # Ignore invalid puppetvars
              end
            end
            Array(*entry["puppetclasses"]).each do |memberNetgroup|
              hosts += get_hosts(memberNetgroup) #get subgroups
            end
          end
          # for array resolution we just append to the array whatever
          # we find, we then goes onto the next file and keep adding to
          # the array
          #
          # for priority searches we break after the first found data item
          case resolution_type
          when :array
            answer << Backend.parse_answer(data[key], scope)
          else
            answer = Backend.parse_answer(data[key], scope)
            break
          end
        end

        return answer
      end
    end
  end
end
