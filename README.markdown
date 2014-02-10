# hiera-ldap backend

This module allows hiera to look up entries in LDAP. It will return an array of every matching entry, with that entry represented as a hash of attribute => value. For multivalued attributes, they exist as multiattribute => [attrib1, attrib2, attrib3].

# Installation

This module can be placed in your puppet module path and will be pluginsync'd to the master.

# Use

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
  :base: ou=People,dc=cat,dc=pdx,dc=edu
  :host: ldap.cat.pdx.edu
  :port: 636
  :encryption: :simple_tls
  :auth:
    :method: :simple
    :username: uid=network,ou=Netgroup,dc=cat,dc=pdx,dc=edu
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

# Details

- It wraps the pramaters to Net::LDAP.new so anything you can do there you can do here


# Advanced

The key being looked up is actually processsed just like rfc4515 so you can use advanced ldap searches:

    hiera('(|(uid=nibz)(uidNumber=1861))')

# Authors

  - Hunter Haugen    http://github.com/hunner
  - Spencer Krum     http://github.com/nibalizer
  - Sage Imel        http://github.com/nightfly
  - Fabio Rauber     http://github.com/fabiorauber
  - Arnaud Gomes     http://forge.ircam.fr/p/hiera-ldap-backend/
