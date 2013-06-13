# hiera-ldap backend

Unfortunately this will still be clunky because LDAP doesn't support complex
data structures, nor arbitrary keys other than what is defined in its schema.
So basically ruby hashes and arrays have to be encoded in the LDAP 'puppetvars'
or 'hieravars' attributes.

This is by no means finished.

- It should accept auth parameters


## Ldap example:

dn: uid=nibz,ou=People,dc=catnip
loginShell: /usr/bin/zsh
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: podPerson
uid: nibz
uidNumber: 1861
gidNumber: 300
homeDirectory: /u/nibz
gecos: Spencer O Krum
cn: Spencer O Krum
sn: Krum
givenName: Spencer
mail: nibz@cecs.pdx.edu


## Configuration example
<pre>

:ldap:
  :base: ou=People,dc=catnip
  :host: ldap.cat.pdx.edu
  :port: 636
  :encryption: :simple_tls
  :auth:
    :method: :simple
    :username: uid=network,ou=Netgroup,dc=catnip
    :password: PASSWORD

</pre>

## Puppet example

  # get info from ldap and put into a hash

  $rooter_info = hiera("uid=${username}")
  if $rooter_info == undef {
    fail ("Hiera/LDAP look up on ${username} failed. Aborting.")
  }

  # use the hashdata to fill out user paramaters
  # as of now, the ldap/hiera backend downcases ldap attributes

  user { $username:
    ensure     => present,
    gid        => 'root',
    uid        => $rooter_info['uidnumber'],
    home       => $rooter_info['homedirectory'],
    managehome => true,
    shell      => $rooter_info['loginshell'],
    comment    => $rooter_info['gecos'],
  }




