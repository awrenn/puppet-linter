# Configuration specific to CentOS 6.
class profile::os::linux::redhat::centos6 {
  include profile::repo::params

  yumrepo {
    default:
      gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
      proxy    => $profile::repo::params::proxy_url,
      enabled  => '1',
      gpgcheck => '1',
    ;
    'contrib':
      descr   => 'CentOS-$releasever - Contrib',
      baseurl => 'http://vault.centos.org/6.10/contrib/$basearch/',
    ;
    'debug':
      descr   => 'CentOS-6 - Debuginfo',
      baseurl => 'http://debuginfo.centos.org/6/$basearch/',
      gpgkey  => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Debug-6',
      enabled => '0',
    ;
  }
}
