# mysql database configuration
class profile::mysql::repo {
  case $facts['os']['name'] {
    'centos': {
      yumrepo { 'mysql-5.7-yum-repo':
        enabled  => 1,
        descr    => 'MySQL 5.7 Community Repo',
        baseurl  => 'http://repo.mysql.com/yum/mysql-5.7-community/el/7/$basearch/',
        gpgcheck => 0,
      }
    }
    'ubuntu', 'debian': {
      apt::source { 'mariadb':
        location => 'http://ftp.osuosl.org/pub/mariadb/repo/10.0/debian',
        release  => $lsbdistcodename,
        repos    => 'main',
        key      => {
          'id'  => 'cbcb082a1bb943db',
          'src' => true,
        },
      }
    }
    default:  {  }
  }

}
