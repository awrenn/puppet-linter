# Deploys the delivery.puppetlabs.net certificate, chain, and key.
#
# Note that in this class, the chain file only contains intermediate certs.
# In other classes, it contains the server cert as well. It appears that this
# class behaves correctly. See Apache's SSLCertificateChainFile documentation.
class profile::ssl::delivery_wildcard {
  include ssl

  $certfile = "${ssl::cert_dir}/delivery.puppetlabs.net.crt"
  $combined_file = "${ssl::cert_dir}/delivery.puppetlabs.net_combined.crt"
  $certchainfile = "${ssl::cert_dir}/delivery.puppetlabs.net_inter.crt"
  $keyfile = "${ssl::key_dir}/delivery.puppetlabs.net.key"

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => '0',
      mode   => '0644',
    ;
    $keyfile:
      # https://github.com/voxpupuli/hiera-eyaml/issues/264: eyaml drops newline
      content => ssl::ensure_newline($ssl::keys['wildcard.delivery.puppetlabs.net']),
      mode    => '0400',
    ;
    $certfile:
      source => 'puppet:///modules/profile/ssl/wildcard.delivery.puppetlabs.net.crt',
    ;
    $certchainfile:
      source => 'puppet:///modules/profile/ssl/wildcard.delivery.puppetlabs.net_inter.crt',
    ;
    $combined_file:
      source => 'puppet:///modules/profile/ssl/wildcard.delivery.puppetlabs.net_combined.crt',
    ;
  }
}
