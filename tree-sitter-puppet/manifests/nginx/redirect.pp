# Redirect everything to another URL
#
# This permanently redirects $hostnames (defaulting to $name) URLs to the same
# URI, but prefixed with $destination.
#
# For example, if $destination is https://puppet.com/old and $hostnames is
# ['puppetlabs.com'], then http://puppetlabs.com/community/overview will be
# redirected to https://puppet.com/old/community/overview
#
# The virtual host will be named "${name}-redirect"
#
# Parameters:
#   [*hostnames*]   - FQDNs to handle. Defaults to $name.
#   [*destination*] - Destination URL prefix.
#   [*default*]     - Handle requests not handled by other virtual hosts.
#   [*ssl*]         - Enable HTTPS.
#   [*ssl_only*]    - Only handle HTTPS requests.
#   [*ssl_cert*]    - SSL combined certificate path. If this is not set, but
#                     $ssl is, then the correct certificate will be determined
#                     (if possible) by $hostnames[0], unless that is 'default',
#                     in which case it is determined by $::fqdn.
#   [*ssl_key*]     - SSL private key path.
#   [*type*]        - Permanent (301) or temporary (302) redirect.

define profile::nginx::redirect (
  Pattern[/^https?:\/\/./]   $destination,
  Array[String[1], 1]        $hostnames = [$name],
  Boolean                    $default   = false,
  Boolean                    $ssl       = true,
  Boolean                    $ssl_only  = false,
  Optional[String[1]]        $ssl_cert  = undef,
  Optional[String[1]]        $ssl_key   = undef,
  Enum[permanent, temporary] $type      = permanent,
) {
  include profile::server::params

  if $default {
    $default_option = { 'listen_options' => 'default_server' }
  } else {
    $default_option = {}
  }

  # Choose a vhost name that sorts to the end so that if $default is false,
  # the redirect will least likely to be matched. This means that hitting the
  # host by IP will not redirect by default, and that the redirect vhost will
  # not provide the default SSL certificate if SNI is not enabled.
  #
  # This is not set conditionally on $default for consistency.
  $vhost = "zzz-${name}-redirect".regsubst('\*', 'wildcard', 'G')

  if $ssl {
    if $::profile::server::params::fw {
      include profile::fw::https
    }

    if $ssl_only {
      $ssl_only_option = { 'listen_port' => 443 }
    } else {
      $ssl_only_option = {}
    }

    if $ssl_cert and $ssl_key {
      $ssl_info = {
        'ssl'      => true,
        'ssl_cert' => $ssl_cert,
        'ssl_key'  => $ssl_key,
      }
    } else {
      # Determine key and cert based on hostname
      if $ssl_cert or $ssl_key {
        fail('Both $ssl_cert and $ssl_key or neither must be set on profile::nginx::redirect')
      }

      if $hostnames[0] == 'default' {
        $info = profile::ssl::host_info($facts['networking']['fqdn'])
      } else {
        $info = profile::ssl::host_info($hostnames[0])
      }
      $ssl_info = {
        'ssl'      => true,
        'ssl_cert' => $info['cert'],
        'ssl_key'  => $info['key'],
      }
    }
  } else {
    # No SSL
    if $ssl_only {
      fail('$ssl_only requires $ssl on profile::nginx::redirect')
    } elsif $ssl_cert {
      fail('$ssl_cert requires $ssl on profile::nginx::redirect')
    } elsif $ssl_key {
      fail('$ssl_key requires $ssl on profile::nginx::redirect')
    }

    if $::profile::server::params::fw {
      include profile::fw::http
    }

    $ssl_info = {
      'ssl'  => false,
    }

    $ssl_only_option = {}
  }

  include profile::nginx

  $redirect_code = $type ? {
    'permanent' => '301',
    'temporary' => '302',
  }

  nginx::resource::server { $vhost:
    server_name          => $hostnames,
    use_default_location => false,
    raw_append           => "\n  return ${redirect_code} ${destination}\$request_uri;",
    format_log           => 'logstash_json',
    access_log           => '/var/log/nginx/access.log',
    error_log            => '/var/log/nginx/error.log',
    *                    => $default_option + $ssl_only_option + $ssl_info,
  }

  if $::profile::server::params::logging {
    include profile::nginx::logging
  }
}
