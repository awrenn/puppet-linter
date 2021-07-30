class profile::dns::common (
  String[1] $ddnskeyname,
  Sensitive[String[1]] $sensitive_ddns_secret,
) {

  include profile::server::params

  class { 'bind':
    customoptions     => "check-names master ignore;\nallow-recursion { 192.168.0.0/16; 10.0.0.0/8; 35.199.192.0/19; };\n",
    enable_statistics => true,
  }

  bind::key { $ddnskeyname:
    algorithm => 'hmac-md5',
    secret    => unwrap($sensitive_ddns_secret),
  }

  # Hold bind9 package and dnsutils packages from auto-updating
  ::apt::pin { 'bind9':
    packages => 'bind9',
    priority => 1001,
    version  => '1:9.10.3.dfsg.P4-12.3+deb9u7',
  }
  ::apt::pin { 'dnsutils':
    packages => 'dnsutils',
    priority => 1001,
    version  => '1:9.10.3.dfsg.P4-12.3+deb9u7',
  }

}
