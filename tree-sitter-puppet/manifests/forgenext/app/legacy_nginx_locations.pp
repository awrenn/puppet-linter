define profile::forgenext::app::legacy_nginx_locations(
  # Enum variants should be limited to nginx::resource::server resources declared in
  # manifests that are a part of the forge app (e.g. forgenext/api.pp, forgenext/web.pp)
  Enum['forge-api', 'forge-web'] $nginx_server,
) {
  nginx::resource::location { "${nginx_server} - releases legacy":
    server              => $nginx_server,
    location_custom_cfg => {
      'rewrite ^/api/v1/releases\.json' => '/v1/releases.json break',
      'include'                         => '/etc/nginx/legacy-proxy.conf',
    },
    location            => '= /api/v1/releases.json',
  }

  nginx::resource::location { "${nginx_server} - modules.json legacy":
    server              => $nginx_server,
    location_custom_cfg => {
      'rewrite ^/modules\.json' => '/v1/modules.json break',
      'include'                 => '/etc/nginx/legacy-proxy.conf',
    },
    location            => '= /modules.json',
  }

  # Legacy web requests
  nginx::resource::location { "${nginx_server} - system releases legacy":
    server              => $nginx_server,
    location_custom_cfg => {
      'rewrite ^/system/releases/([^\/]+)/([^\/]+)/([^\/]+)' => '/v3/files/$3 break',
      'include'                                              => '/etc/nginx/legacy-proxy.conf',
    },
    location            => '~ ^\/system\/releases\/(.+)',
  }
}
