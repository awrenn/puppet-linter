class profile::gitdaemon (
  Pattern[/^\//] $base_path = '/srv/git',
) {
  Account::User <| tag == 'git' |>

  package { 'git':
    ensure => latest,
    notify => Service['gitdaemon.socket'],
  }

  file {
    default:
      ensure => file,
      owner  => 'root',
      group  => '0',
      mode   => '0444',
      notify => Service['gitdaemon.socket'],
    ;
    '/etc/default/gitdaemon':
      mode    => '0644',
      content => epp('profile/gitdaemon/environment.epp', {
        base_path => $base_path,
      })
    ;
    '/etc/systemd/system/gitdaemon@.service':
      source => 'puppet:///modules/profile/gitdaemon/gitdaemon@.service',
    ;
    '/etc/systemd/system/gitdaemon.socket':
      source => 'puppet:///modules/profile/gitdaemon/gitdaemon.socket',
    ;
  }

  service { 'gitdaemon.socket':
    ensure     => running,
    enable     => true,
    hasrestart => true,
  }
}
