# Permit the Puppet admins group to
# purge nodes
class profile::pe::allow_admin {

  $admins      = 'Puppet Admins'
  $puppet      = '/opt/puppetlabs/bin/puppet'
  $no_passwd   = 'ALL=(ALL) NOPASSWD:'
  $cert_regexp = '[a-zA-Z0-9._-][a-zA-Z0-9._-]*'

  Account::User <| groups == 'puppet-admins' |>
  realize(Group['puppet-admins'])
  ssh::allowgroup  { 'puppet-admins': }

  sudo::entry {
    "${admins}: Node Purge":
      entry => "%puppet-admins ${no_passwd} ${puppet} node purge ${cert_regexp}",
  }
}
