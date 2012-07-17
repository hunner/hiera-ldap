# hiera-ldap plugin

Unfortunately this will still be clunky because LDAP doesn't support complex
data structures, nor arbitrary keys other than what is defined in its schema.
So basically ruby hashes and arrays have to be encoded in the LDAP 'puppetvars'
or 'hieravars' attributes.

This is by no means finished.

- It should accept auth parameters

### ldap example...
ou=hosts,cn=$fqdn
  puppetvars:
    - maxmem=2048
    - { 'classes' => {'ntp' => { 'ntp_servers' => ['10.0.0.1'] }}}
cn=pdx,dc=datacenters
  puppetvars:
    - maxmem=1024
  ssh_users:
