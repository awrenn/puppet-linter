# Manage the .fog file used by the compliance team
#
class profile::compliance::fog (
  Sensitive[String[1]] $sensitive_default_abs_token,
  String[1] $svc_account = 'ghactions',
) {
  realize(Group[$svc_account])
  realize(Account::User[$svc_account])

  # Every entry for the .fog file should be represented in this hash and have a
  # corresponding class paramater if overrides are applicable. All secrets should
  # be added to hiera and encrypted with eyaml.
  $fog_hash = {
    'default' => {
      'abs_token'      => unwrap($sensitive_default_abs_token),
    },
  }

  file { "/home/${svc_account}/.fog":
    ensure  => file,
    mode    => '0640',
    owner   => $svc_account,
    group   => $svc_account,
    content => to_symbolized_yaml($fog_hash).node_encrypt::secret,
    require => Account::User[$svc_account],
  }

  File <| title == "/home/${svc_account}/.fog" |> ~> Service <| tag == 'ghactions-service' |>
}
