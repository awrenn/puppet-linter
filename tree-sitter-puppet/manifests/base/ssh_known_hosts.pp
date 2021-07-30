# Set up the global known_hosts file.
#
# sshkey only seems to allow one key type for each host. This is specified to
# be rsa until extensive testing has been completed.
class profile::base::ssh_known_hosts (
  Enum[ecdsa, ed25519, rsa] $key_type = rsa,
  Boolean $gather_all_ssh_keys = false,
) {
  sshkey { 'github.com':
    key  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==',
    type => 'ssh-rsa',
  }

  $key_info = $facts.dig('ssh', $key_type)
  if $key_info and $key_info['type'] {
    sshkey { 'localhost':
      host_aliases => ['127.0.0.1', '::1'],
      key          => $key_info['key'],
      type         => $key_info['type'],
    }
  }

  if $gather_all_ssh_keys {
    puppetdb_query('inventory[certname, facts] {}').each |$index, $data| {
      # Only act on results that have a fqdn
      if $data.dig('facts', 'fqdn') {
        $key_info = $data.dig('facts', 'ssh', $key_type)
        if $key_info and $key_info['type'] {
          $selected_key_info = $key_info
        } else {
          # If we couldn't find the preferred SSH key type, then fall back to rsa.
          $rsa_key_info = $data.dig('facts', 'ssh', 'rsa')
          if $rsa_key_info and $rsa_key_info['type'] {
            $selected_key_info = $rsa_key_info
          } else {
            $selected_key_info = undef
          }
        }

        if $selected_key_info {
          # $aliases should never contain the certname, since that's specified as
          # the name of the sshkey.
          if $data['certname'] == $data['facts']['fqdn'] {
            $aliases = [$data['facts']['primary_ip']].delete_undef_values()
          } else {
            $aliases = [$data['facts']['fqdn']] + [$data['facts']['primary_ip']].delete_undef_values()
          }

          sshkey { $data['certname']:
            host_aliases => $aliases,
            key          => $selected_key_info['key'],
            type         => $selected_key_info['type'],
          }
        }
      }
    }
  }
}
