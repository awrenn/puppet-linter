class profile::imaging::builder::prerequisites {

  include java
  include profile::aws::cli

  ensure_packages([
    'patch',
    'kernel-devel',
    'libXtst',
    'dkms',
    'xorg-x11-fonts-Type1',
    'xorg-x11-server-Xvfb',
    'xorg-x11-xauth',
    'tree',
    'cmake3',
  ], {'ensure' => 'present' })
}
