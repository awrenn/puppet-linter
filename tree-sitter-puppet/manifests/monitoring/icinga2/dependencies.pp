class profile::monitoring::icinga2::dependencies {
  # Dependencies are specified in this class as apply rules

  icinga2::object::apply_dependency {
    default:
      object_type         => 'Service';
    'parent-dependency':
      parent_service_name => 'service.vars.parent_service',
      child_service_name  => 'service.name',
      assign_where        => 'service.vars.parent_service',
  }
}
