class profile::dns::deploy::remove {

  # ----------
  # REMOVE: Server Updates
  # ----------
  cron { 'update dns zones':
    ensure  => absent,
    command => '/usr/local/sbin/dnsscript.sh',
    minute  => '*/5',
    user    => 'root',
  }

  file{ '/usr/local/sbin/dnsscript.sh':
    ensure => absent,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/mrepo_service/dns/dnsscript.sh',
  }
}
