# Deploys the SSL Cert and Key to the HTTPS Support Upload Server 
# (Managed by IT Ops and used by Customer Support)
class profile::ssl::support_upload {
  include ssl

  $keyfile = "${ssl::key_dir}/support-upload.puppetlabs.com.key"
  $certfile = "${ssl::cert_dir}/support-upload.puppetlabs.com.crt_combined"
  $certchainfile = "${ssl::cert_dir}/support-upload.puppetlabs.com_chain.crt"

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => '0',
      mode   => '0644',
    ;
    $keyfile:
      # https://github.com/voxpupuli/hiera-eyaml/issues/264: eyaml drops newline
      content => ssl::ensure_newline($ssl::keys['support-upload.puppetlabs.com']),
      mode    => '0400',
    ;
    $certfile:
      source => 'puppet:///modules/profile/ssl/support-upload.puppetlabs.com_combined.crt',
    ;
    $certchainfile:
      source => 'puppet:///modules/profile/ssl/support-upload.puppetlabs.com_chain.crt',
    ;
  }

  $hashfiles = [ $certfile, $certchainfile ]
  ssl::hashfile { $hashfiles: certdir => $ssl::cert_dir }
}
