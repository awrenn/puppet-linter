# Linux, macOS, Solaris
class profile::os::splatnix (
  Sensitive[String[1]] $sensitive_raw_root_password, # raw password that is encoded here as needed
  Sensitive[String[1]] $sensitive_complex_salt_root_password, # salt used on OS X / macOS 10.8+
  Sensitive[String[1]] $sensitive_simple_salt_root_password, # salt used on Linux and Solaris
  Boolean $purge_cron = false,
) {
  include profile::access::dio
  include profile::access::itops
  include profile::base::ssh_known_hosts
  include profile::motd
  include profile::veeam

  realize Account::User['infracorepd']
  ssh::allowgroup { 'infracorepd': }

  if $purge_cron {
    resources { 'cron': purge => true }
  }

  $shell = $facts['kernel'] ? {
    'SunOS' => '/usr/bin/bash',
    default => '/bin/bash',
  }

  if $facts['kernel'] == 'Darwin' {
    $pw_info = Sensitive.new(str2saltedpbkdf2($sensitive_raw_root_password, $sensitive_complex_salt_root_password, 50000))
    user { 'root':
      ensure         => present,
      comment        => 'root',
      gid            => '0',
      home           => '/root',
      iterations     => unwrap($pw_info)['iterations'],
      password       => unwrap($pw_info)['password_hex'],
      salt           => unwrap($pw_info)['salt_hex'],
      shell          => $shell,
      uid            => '0',
      purge_ssh_keys => true,
    }
  } else {
    user { 'root':
      ensure         => present,
      comment        => 'root',
      gid            => '0',
      home           => '/root',
      password       => pw_hash($sensitive_raw_root_password, 'SHA-512', unwrap($sensitive_simple_salt_root_password)),
      shell          => $shell,
      uid            => '0',
      purge_ssh_keys => true,
    }
  }

  file { '/root/.ssh':
    ensure => directory,
    mode   => '0700',
    owner  => '0',
    group  => '0',
  }

  $rsa_key_ensure = $profile::os::root_rsa_pub_key ? {
    String[1] => 'present',
    default   => 'absent',
  }

  ssh_authorized_key {
    default:
      user    => 'root',
      require => User['root'],
    ;
    'root_rsa_pub_key':
      ensure => $rsa_key_ensure,
      key    => $profile::os::root_rsa_pub_key,
      type   => 'ssh-rsa',
    ;
    'root_ed25519_pub_key':
      ensure => present,
      key    => $profile::os::root_ed25519_pub_key,
      type   => 'ssh-ed25519',
    ;
  }
}
