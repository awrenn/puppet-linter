# Class: profile::jenkins::usage::ruby
#
class profile::jenkins::usage::ruby {
  case $facts['os']['family'] {
    'Windows': { include profile::jenkins::usage::ruby::pik }
    default:   { include profile::jenkins::usage::ruby::rvm }
  }
}
