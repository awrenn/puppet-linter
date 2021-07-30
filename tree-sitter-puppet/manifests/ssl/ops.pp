# Deploys the *.ops.puppetlabs.net wildcard certificate, chain, and key.
class profile::ssl::ops {
  include ssl

  $cert_file = "${ssl::cert_dir}/wildcard.ops.puppetlabs.net.crt"
  $combined_file = "${ssl::cert_dir}/wildcard.ops.puppetlabs.net_combined.crt"
  $intermediate_file = "${ssl::cert_dir}/wildcard.ops.puppetlabs.net_inter.crt"
  $keyfile = "${ssl::key_dir}/wildcard.ops.puppetlabs.net.key"

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => '0',
      mode   => '0644'
    ;
    $keyfile:
      # https://github.com/voxpupuli/hiera-eyaml/issues/264: eyaml drops newline
      content => ssl::ensure_newline($ssl::keys['wildcard.ops.puppetlabs.net']),
      mode    => '0400',
    ;
    $cert_file:
      source => 'puppet:///modules/profile/ssl/wildcard.ops.puppetlabs.net.crt',
    ;
    $intermediate_file:
      source => 'puppet:///modules/profile/ssl/wildcard.ops.puppetlabs.net_inter.crt',
    ;
    $combined_file:
      source => 'puppet:///modules/profile/ssl/wildcard.ops.puppetlabs.net_combined.crt',
    ;
  }
}
