# Class: profile::ssl::wildcard
#
# Deploys the *.puppetlabs.com wildcard certificate, chain, and key.
#
class profile::ssl::wildcard {
  include ssl

  $keyfile = "${ssl::key_dir}/puppetlabs_wildcard.key"
  $certfile = "${ssl::cert_dir}/puppetlabs_wildcard.crt"
  $certchainfile = "${ssl::cert_dir}/puppetlabs_wildcard_chain.crt"
  $certinterfile = "${ssl::cert_dir}/puppetlabs_wildcard_inter.crt"
  $certinter2file = "${ssl::cert_dir}/puppetlabs_wildcard_inter2.crt"

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => '0',
      mode   => '0644',
    ;
    $keyfile:
      # https://github.com/voxpupuli/hiera-eyaml/issues/264: eyaml drops newline
      content => ssl::ensure_newline($ssl::keys['puppetlabs_wildcard']),
      mode    => '0400',
    ;
    $certfile:
      source => 'puppet:///modules/profile/ssl/puppetlabs_wildcard.crt',
    ;
    $certchainfile:
      source => 'puppet:///modules/profile/ssl/puppetlabs_wildcard_chain.crt',
    ;
    $certinterfile:
      source => 'puppet:///modules/profile/ssl/puppetlabs_wildcard_inter.crt',
    ;
    # Second level intermediate cert
    $certinter2file:
      source => 'puppet:///modules/profile/ssl/pl_inter2.cert',
    ;
  }

  $hashfiles = [ $certfile, $certchainfile, $certinterfile, $certinter2file ]
  ssl::hashfile { $hashfiles: certdir => $ssl::cert_dir }
}
