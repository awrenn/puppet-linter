# A key to sign aptly repos with
define profile::aptly::key (
  Sensitive[String[1]]      $private_key,
  Pattern[/^[0-9A-F]{16}$/] $private_key_id = $name,
) {
  include profile::aptly

  $private_key_path = "${::profile::aptly::keys_path}/${private_key_id}.key"
  file { $private_key_path:
    ensure    => file,
    owner     => 'aptly',
    group     => 'aptly',
    mode      => '0400',
    content   => unwrap($private_key),
    show_diff => false,
    notify    => Exec["gpg import ${private_key_id}"],
  }

  exec { "gpg import ${private_key_id}":
    command     => "/usr/bin/gpg --import ${private_key_path}",
    refreshonly => true,
    user        => 'aptly',
    environment => 'HOME=/home/aptly',
    require     => Package['gnupg'],
  }
}
