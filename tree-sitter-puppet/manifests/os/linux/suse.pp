class profile::os::linux::suse {
  # make sure repos are in place before packages are installed
  Zypprepo<| |> -> Package<| |>

  zypprepo { 'utilities':
    baseurl     => 'https://download.opensuse.org/repositories/utilities/SLE_12_SP5/',
    enabled     => 1,
    autorefresh => 1,
    descr       => 'all the small tools for the shell (SLE_12_SP5)',
    gpgcheck    => 1,
    gpgkey      => 'https://download.opensuse.org/repositories/utilities/SLE_12_SP5/repodata/repomd.xml.key',
    type        => 'rpm-md',
  }
}
