# eyaml encryption configuration
#
# This is appropriate for any node on which you'd like to be able to encrypt
# things with eyaml. It does not install any private data.
#
# See also `profile::eyaml::private`. You may use the two profiles together,
# though the private class includes this one.
class profile::eyaml (
  String[1] $file_ensure = file,
) {
  $directory_ensure = $file_ensure ? {
    'absent' => absent,
    'purged' => absent,
    default  => directory,
  }

  file {
    default:
      owner => 'root',
      group => 'root',
    ;
    '/etc/puppetlabs/puppet/eyaml':
      ensure => $directory_ensure,
      mode   => '0755',
    ;
    '/etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem':
      ensure => $file_ensure,
      mode   => '0444',
      source => 'puppet:///modules/profile/eyaml/public_key.pkcs7.pem',
    ;
  }
}
