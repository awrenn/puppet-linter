class profile::active_directory {
  class { 'windows_ad':
    install                => present,
    installmanagementtools => true,
    restart                => true,
    installflag            => true,
    configure              => present,
    configureflag          => true,
    domain                 => 'forest',
    domainname             => hiera('profile::active_directory::domainname', 'puppetlabs.local'),
    netbiosdomainname      => hiera('profile::active_directory::netbiosdomainname', 'puppetlabs'),
    domainlevel            => 'Default',
    forestlevel            => 'Default',
    databasepath           => 'c:\\windows\\ntds',
    logpath                => 'c:\\windows\\ntds',
    sysvolpath             => 'c:\\windows\\sysvol',
    installtype            => 'domain',
    dsrmpassword           => hiera('profile::active_directory::dsrmpassword', 'puppet'),
    installdns             => 'yes',
    localadminpassword     => hiera('profile::active_directory::localadminpassword', 'puppet'),
  }

  include profile::active_directory::create_ou
  include profile::active_directory::create_user
}
