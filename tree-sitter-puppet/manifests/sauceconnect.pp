class profile::sauceconnect {

  profile_metadata::service { $title:
    human_name => 'SuaceConnect Tunnel',
    team       => dio,
  }

  class { '::sauceconnect':
    sauce_user  => 'puppetlabs',
    sauce_key   => '7f01e6af-db08-4cc4-b25c-49481cfb96f3',
    daemon_args => "-F \\'^https?://www\\.google-analytics\\.com\\' --no-remove-colliding-tunnels",
  }

  # OPS-13868
  ssh::allowgroup { 'developers': }
  Account::User <| groups == 'developers' |>
  Group         <| title == 'developers' |>

  # OPS-14432
  sudo::allowgroup { 'developers': }
}
