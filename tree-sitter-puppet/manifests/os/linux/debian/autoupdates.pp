# Provide a class to manage debian autupdates
class profile::os::linux::debian::autoupdates (
  $remove_unused_dependencies    = true,
  $mail_on_error                 = true,
  $mail_user                     = 'root',
  $auto_fix_interrupted_dpkg     = true,
  $minimal_steps                 = false,
  $install_on_shutdown           = false,
  $repos_to_update               = undef,
  $dl_limit                      = undef,
  $update_package_lists          = 1,
  $download_upgradeable_packages = 1,
  $run_every                     = 1,
  $autoclean                     = 21,
  $mail_verbosity                = 1,
  $update_stable                 = true,
  $update_security               = true,
  $update_days                   = undef,
  $force_confold                 = true,
  Array[String[1]] $additional_excludes = [],
) {

  # This variable is referenced in the erb template to enabled autoupdates
  $unattended_upgrades = $::profile::os::linux::debian::autoupdates

  if $unattended_upgrades {
    $ensure_autoupdates = present

    $excludes = profile::os::linux::autoupdates::get_exclusions('apt', $additional_excludes)
    $exclude = $excludes.map |$name| { "'${name}';" }.join("\n")
  } else {
    $ensure_autoupdates = absent
  }

  package { [ 'unattended-upgrades', 'apt-listchanges' ]:
    ensure => $ensure_autoupdates,
  }

  file {
    default:
      ensure  => $ensure_autoupdates
      ;
    '/etc/apt/apt.conf.d/02periodic':
      mode    => '0444',
      content => template('profile/os/linux/debian/autoupdates.erb')
      ;
    '/usr/local/bin/apt-autoupdates':
      mode   => '0500',
      source => "puppet:///modules/profile/os/linux/debian/apt_daily_${facts['os']['distro']['codename']}"
      ;
    '/etc/cron.daily/apt':
      ensure => absent
      ;
    '/etc/apt/apt.conf.d/50unattended-upgrades':
      ensure => absent,
      ;
  }

  cron { 'unattended-upgrades':
    ensure  => $ensure_autoupdates,
    command => '/usr/local/bin/apt-autoupdates',
    weekday => $update_days,
    hour    => 9,
    minute  => 0,
  }

  if ($profile::server::logging) and ($unattended_upgrades) {
    # No logstash-forwarder package is available for newer versions of Debian
    if Integer($facts['os']['release']['major']) < 9 {
      include profile::logging::logstashforwarder
      logstashforwarder::file { 'unattended_upgrades':
        paths  => [ '/var/log/unattended-upgrades/unattended-upgrades-dpkg*.log' ],
        fields => { 'type' => 'unattendedupgrades' },
        before => Class['logstashforwarder'],
      }
    }
  }
}
