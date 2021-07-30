# *.puppet.com cert
class profile::ssl::puppet_wildcard {
  include ssl

  ssl::cert::nginx { 'wildcard.puppet.com': }

  $certfile = "${ssl::cert_dir}/wildcard.puppet.com.crt"
  $keyfile = "${ssl::key_dir}/wildcard.puppet.com.key"
  $certchainfile = $certfile
}
