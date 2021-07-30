# == Class: profile::nginx::loadbalancer
#
# Nginx Loadbalancer Profile
#
# === Authors
#
#  Puppet Ops <opsteam@puppetlabs.com>
#
# === Copyright
#
# Copyright 2013 Puppet Labs, unless otherwise noted.
#
define profile::nginx::loadbalancer (
  $isdefaultvhost         = true,
  $workers                = undef,
  $caches                 = '',
  $location_template      = undef,
  $rootlocation_template  = undef,
  $proto                  = 'http',
  $serveraliases          = undef,
  $ipv6only               = true,
) {

  include profile::nginx

  meta_motd::register { "Profile: nginx::loadbalancer for ${name}.": }

  if (($location_template != undef) and ($rootlocation_template != undef)) {
    ::nginx::loadbalancer { $name:
      workers        => $workers,
      ssl            => true,
      caches         => $caches,
      locations      => template($location_template),
      rootlocation   => template($rootlocation_template),
      isdefaultvhost => $isdefaultvhost,
      proto          => $proto,
      serveraliases  => $serveraliases,
      ipv6only       => $ipv6only,
      require        => Class['puppetlabs::ssl'],
    }
  } elsif $location_template != undef {
    ::nginx::loadbalancer { $name:
      workers        => $workers,
      ssl            => true,
      caches         => $caches,
      locations      => template($location_template),
      isdefaultvhost => $isdefaultvhost,
      serveraliases  => $serveraliases,
      ipv6only       => $ipv6only,
      require        => Class['puppetlabs::ssl'],
    }
  } elsif $rootlocation_template != undef {
    ::nginx::loadbalancer { $name:
      workers        => $workers,
      ssl            => true,
      caches         => $caches,
      rootlocation   => template($rootlocation_template),
      isdefaultvhost => $isdefaultvhost,
      serveraliases  => $serveraliases,
      ipv6only       => $ipv6only,
      require        => Class['puppetlabs::ssl'],
    }
  } else {
    ::nginx::loadbalancer { $name:
      workers        => $workers,
      ssl            => true,
      caches         => $caches,
      isdefaultvhost => $isdefaultvhost,
      serveraliases  => $serveraliases,
      ipv6only       => $ipv6only,
      require        => Class['puppetlabs::ssl'],
    }
  }
}
