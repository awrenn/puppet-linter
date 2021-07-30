# Class: profile::mongodb::db
#
class profile::mongodb::db {
  include profile::mongodb::params

  $db = $::profile::mongodb::params::db

  if $db {
    create_resources('::mongodb::db', $db)
  }
}
