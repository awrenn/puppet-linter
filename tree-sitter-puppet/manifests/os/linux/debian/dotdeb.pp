# Class: profile::os::linux::debian::dotdeb
#
# Add apt sources and include modules specific to dotdeb repos
#
class profile::os::linux::debian::dotdeb {

  # Add Dotdeb repo
  apt::source { 'dotdeb-main':
    location => 'http://packages.dotdeb.org',
    include  => { 'src' => true },
    repos    => 'all',
  }

  apt::key { 'dotdeb-gpg-key':
    key    => '6572BBEF1B5FF28B28B706837E3F070089DF5277',
    source => 'https://www.dotdeb.org/dotdeb.gpg',
  }

  apt::source { 'php-56':
    location => 'http://packages.dotdeb.org',
    include  => { 'src' => true },
    repos    => 'all',
    release  => 'wheezy-php56-zts',
  }
}
