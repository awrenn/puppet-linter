# Remove unmanaged firewall rules.
class profile::fw::purge {
  resources { 'firewall':
    purge => true,
  }
}
