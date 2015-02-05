source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :development, :unit_tests do
  gem 'ladle', '~> 1.0.0',       :require => false
  gem 'rspec', '~> 2.10.0',      :require => false
  gem 'mocha', '~> 0.10.5',      :require => false
end

# Test Against Multiple Hiera in Travis
if hieraversion = ENV['HIERA_GEM_VERSION']
  gem 'hiera', hieraversion, :require => false
else
  gem 'hiera', :require => false
end

# Test Against Multiple net-ldap gems in Travis
if netldapversion = ENV['NETLDAP_GEM_VERSION']
  gem 'net-ldap', netldapversion, :require => false
else
  gem 'net-ldap', :require => false
end

# vim:ft=ruby