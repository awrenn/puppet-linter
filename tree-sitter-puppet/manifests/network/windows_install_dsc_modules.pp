class profile::network::windows_install_dsc_modules {
  package { 'NetworkingDsc':
    ensure   => latest,
    provider => 'windowspowershell',
    source   => 'PSGallery',
    require  => Pspackageprovider['Nuget'],
  }
}
