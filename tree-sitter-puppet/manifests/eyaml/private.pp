# Install the private key for eyaml.
#
# This is only necessary on Puppet masters.
class profile::eyaml::private (
  Sensitive[String[1]] $sensitive_key,
) {
  include profile::eyaml

  file { '/etc/puppetlabs/puppet/eyaml/private_key.pkcs7.pem':
    ensure  => file,
    owner   => 'root',
    group   => 'pe-puppet',
    mode    => '0440',
    content => $sensitive_key.node_encrypt::secret,
    require => Package['pe-puppetserver'],
  }
}
