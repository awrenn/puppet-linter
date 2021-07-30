# Class: profile::openldap::remove
#
# Implement the removal of OpenLDAP
#
class profile::openldap::remove {
  include openldap::server::remove
}
