class profile::monitoring::icinga2::groups {
  # This class contains apply objects to assign Icinga2 nodes to various host/service groups.
  icinga2::object::hostgroup { 'InfraCore-Nodes':
    assign_where => 'host.vars.owner == "InfraCore"',
  }

  $role_results = query_resources(false, ['and', ['=', 'type', 'Class'], ['~', 'title', 'Role::.*']])
  if is_hash($role_results) {
    $roles = map(flatten(values($role_results))) |$x| { $x['title'] }
  } else {
    $roles = $role_results.map |$x| { $x['title'] }
  }
  # Create hostgroups for each role
  each(unique($roles)) |$role| {
    $role_name = downcase($role)
    icinga2::object::hostgroup { $role_name:
      assign_where => "host.vars.role == \"${role_name}\"",
    }
  }
}
