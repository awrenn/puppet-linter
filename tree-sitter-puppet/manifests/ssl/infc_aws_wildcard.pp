# Deploys the wildcard.infc-aws.puppet.net.key certificate, chain, and key.
class profile::ssl::infc_aws_wildcard {
  include ssl

  $cert_dir = '/opt/puppetlabs/server/data/console-services/certs'
  $certfile = "${cert_dir}/wildcard.infc-aws.puppet.net.crt"
  $combined_file = "${cert_dir}/wildcard.infc-aws.puppet.net_combined.crt"
  $certchainfile = "${cert_dir}/wildcard.infc-aws.puppet.net_inter.crt"
  $keyfile = "${cert_dir}/wildcard.infc-aws.puppet.net.key"

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => '0',
      mode   => '0644',
    ;
    $keyfile:
      # https://github.com/voxpupuli/hiera-eyaml/issues/264: eyaml drops newline
      content => ssl::ensure_newline($ssl::keys['wildcard.infc-aws.puppet.net']),
      mode    => '0400',
    ;
    $certfile:
      source => 'puppet:///modules/profile/ssl/wildcard.infc-aws.puppet.net.crt',
    ;
    $certchainfile:
      source => 'puppet:///modules/profile/ssl/wildcard.infc-aws.puppet.net_inter.crt',
    ;
    $combined_file:
      source => 'puppet:///modules/profile/ssl/wildcard.infc-aws.puppet.net_combined.crt',
    ;
  }
}
