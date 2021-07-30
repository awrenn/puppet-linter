##
#
class profile::apt {
  include profile::repo::params
  include apt
}
