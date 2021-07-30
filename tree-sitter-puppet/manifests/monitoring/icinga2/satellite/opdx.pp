# Configuration specific to the opdx zone should sit here. For example, checks
# which aren't associated with a host that should run from opdx should be created
# in this class.
class profile::monitoring::icinga2::satellite::opdx inherits ::profile::monitoring::icinga2::satellite {

  include profile::monitoring::icinga2::common
  include profile::vmware::monitor
  include profile::abs::monitor
  include profile::cith::monitor

  include ruby
  include ruby::dev

  python::pip { 'requests':
    ensure => latest,
  }
}
