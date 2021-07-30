# Set private key for Code Manager
#
# This assumes that only the directory immediately above the private key needs
# to be managed. I would hard code the paths, but they need to be passed to
# puppet_enterprise::profile::master in hiera, and I want them to be configured
# in only one place.
class profile::pe::code_manager (
  String[1] $r10k_private_key,
) {
  $key_path = lookup('puppet_enterprise::profile::master::r10k_private_key', String[1])
  file {
    default:
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      require => Package['pe-puppetserver'],
    ;
    dirname($key_path):
      ensure  => directory,
      mode    => '0700',
      purge   => true,
      recurse => true,
      force   => true,
    ;
    $key_path:
      ensure  => file,
      mode    => '0600',
      content => $r10k_private_key,
    ;
  }

  # Remove old r10k key
  file { '/root/.ssh/r10k_rsa':
    ensure => absent,
  }
}
