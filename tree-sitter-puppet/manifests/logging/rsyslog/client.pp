# Class: profile::logging::rsyslog::client
#
# Ship logs to centralized logging server
#
class profile::logging::rsyslog::client(
  Stdlib::Port $pe_syslog_port            = 514,
  String       $pe_syslog_protocol_format = 'RSYSLOG_ForwardFormat',
  String       $pe_syslog_remote_type     = 'udp',
  $pe_syslog_server                       = false,
) {

  if $pe_syslog_server {
    $log_remote = true
  } else {
    $log_remote = false
  }

  if $::kernel == 'Linux' {
    if $facts['os']['name'] == 'Debian' {
      if $facts['os']['distro']['codename'] == 'wheezy' {
        package { 'libestr0': ensure => '0.1.9-1~bpo70+1' }
        package { 'librelp0': ensure => '1.2.7-1~bpo70+1' }
      }
    }

    class { 'rsyslog::client':
      log_remote      => $log_remote,
      server          => $pe_syslog_server,
      ssl             => false,
      remote_type     => $pe_syslog_remote_type,
      port            => $pe_syslog_port,
      protocol_format => $pe_syslog_protocol_format,
    }

    # If the host is external, ship the rsyslog logs via logstash-forwarder
    if $facts['networking']['ip'] !~ /^10\.\d+\.\d+\.\d+$/ {
      include profile::logging::logstashforwarder
      $rsyslog_files = [
        '/var/log/syslog', '/var/log/auth.log', '/var/log/cron.log',
        '/var/log/daemon.log', '/var/log/kern.log', '/var/log/lpr.log',
        '/var/log/mail.log', '/var/log/user.log',
      ]
      ::logstashforwarder::file { 'rsyslog_files':
        paths  => $rsyslog_files,
        fields => {
          'type' => 'syslog',
        },
      }
    }
  } else {
    notify { "logging is not supported on ${operatingsystem}": }
  }
}
