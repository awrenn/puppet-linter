class profile::dns::monitor inherits ::profile::monitoring::icinga2::common {

  icinga2::object::service { 'check-dns':
    check_command => 'dns',
    vars          => {
      'dns_lookup'           => '8.8.8.8',
      'dns_expected_answers' => 'google-public-dns-a.google.com.',
    },
  }
}
