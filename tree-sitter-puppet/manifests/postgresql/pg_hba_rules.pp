class profile::postgresql::pg_hba_rules {

  $pg_hba_rules = $::profile::postgresql::params::pg_hba_rules
  create_resources('postgresql::server::pg_hba_rule', $pg_hba_rules)

}
