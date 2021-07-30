# Redirect all domains to the canonical FQDN
class profile::nginx::redirect::all  (
  Pattern[/\./] $canonical_fqdn = $facts['networking']['fqdn'],
) {
  profile::nginx::redirect {
    default:
      destination => "https://${canonical_fqdn}",
      ssl         => true,
    ;
    '*.puppet.com': ;
    '*.puppetlabs.com': ;
    '*.ops.puppetlabs.net': ;
    '*.delivery.puppetlabs.net': ;
  }

  # Override the domain of $canonical_fqdn to be the default responder for SNI
  $info = profile::ssl::host_info($canonical_fqdn)
  Profile::Nginx::Redirect["*.${info['domain']}"] {
    default => true,
  }
}
