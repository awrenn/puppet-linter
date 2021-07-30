# Setup a host to run comply
class profile::pe::comply (
  Stdlib::HTTPSUrl $scanner_source,
  Boolean $manage_java = true,
)  {
  class { 'comply':
    linux_manage_unzip => false,
    scanner_source     => $scanner_source,
    manage_java        => $manage_java,
  }
}
