# Realize all users
class profile::allusers {
  Account::User <| |>
  ssh::allowgroup { 'allstaff': }

  # The pf9 user will fail if this directory does not exist. It's created by
  # other code on the actual Platform9 nodes
  file { '/opt/pf9':
    ensure => directory,
    owner  => 'root',
    group  => '0',
    mode   => '0755',
  }
}
