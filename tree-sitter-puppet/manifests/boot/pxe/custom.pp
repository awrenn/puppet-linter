# Custom PXE boot options
#
# To generate an autosign token, run a command like the following on the MoM,
# then encrypt the output and put it in hiera.
#
#     /opt/puppetlabs/puppet/bin/autosign generate -brt 2592000 \
#       '/\Ap9openstack-compute-prod-[a-z]*-[0-9]*\.ops\.puppetlabs\.net\Z/'
#
# That will create reusable token that expires after 30 days.
#
# If $sensitive_autosign_token is not set it will not try to use autosign.
#
# INFC-17551: Autosign seems to be broken.
class profile::boot::pxe::custom (
  Optional[Sensitive[String]] $sensitive_autosign_token = undef,
) {
  include profile::os::splatnix

  pxe::images { 'centos 7.4.1708 x86_64':
    os      => 'centos',
    ver     => '7.4.1708',
    arch    => 'x86_64',
    netboot => 'netboot',
  }

  file { '/webroot/custom':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    purge   => true,
    force   => true,
    recurse => true,
  }

  $_rpw_hash = Sensitive.new(pw_hash($profile::os::splatnix::sensitive_raw_root_password, 'SHA-512', unwrap($profile::os::splatnix::sensitive_simple_salt_root_password)))

  file { '/webroot/custom/p9openstack-opdx.cfg':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => epp('profile/boot/pxe/custom/p9openstack-opdx.cfg.epp', {
      root_password_hash => $_rpw_hash,
      autosign_token     => $sensitive_autosign_token,
    }).node_encrypt::secret,
  }

  file { '/webroot/custom/p9openstack-opdx-lite.cfg':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => epp('profile/boot/pxe/custom/p9openstack-opdx-lite.cfg.epp', {
      root_password_hash => $_rpw_hash,
      autosign_token     => $sensitive_autosign_token,
    }).node_encrypt::secret,
  }

  pxe::menu { 'Custom':
    file => 'os_custom',
  }

  pxe::menu::entry { 'Installer: p9openstack at OPDX':
    file   => 'os_custom',
    kernel => 'images/centos/7.4.1708/x86_64/vmlinuz',
    append => [
      'initrd=images/centos/7.4.1708/x86_64/initrd.img',
      'repo=http://vault.centos.org/7.4.1708/os/x86_64/',
      'devfs=nomount',
      'ip=dhcp',
      "ks=http://${facts['networking']['fqdn']}/custom/p9openstack-opdx.cfg",
      'vga=792',
      'servername=replace_me',
    ].join(' '),
  }

  pxe::menu::entry { 'Installer: p9openstack lite at OPDX':
    file   => 'os_custom',
    kernel => 'images/centos/7.4.1708/x86_64/vmlinuz',
    append => [
      'initrd=images/centos/7.4.1708/x86_64/initrd.img',
      'repo=http://vault.centos.org/7.4.1708/os/x86_64/',
      'devfs=nomount',
      'ip=dhcp',
      "ks=http://${facts['networking']['fqdn']}/custom/p9openstack-opdx-lite.cfg",
      'vga=792',
      'servername=replace_me',
    ].join(' '),
  }

  file { '/webroot/custom/p9openstack-pix.cfg':
    ensure  => absent,
  }
}
