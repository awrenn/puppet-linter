# Proxy external webhook endpoints to internal hosts
class profile::webhook::proxy (
  String[1] $canonical_fqdn = $facts['networking']['fqdn'],
) {
  profile_metadata::service { $title:
    human_name        => 'GitHub webhook proxy',
    owner_uid         => 'gene.liverman',
    team              => 'dio',
    end_users         => ['discuss-sre@puppet.com'],
    escalation_period => '24x7',
    downtime_impact   => "Internal services aren't notfied about repo changes.",
    other_fqdns       => ['webhook.puppet.com'],
    notes             => @("NOTES"),
      This allows Github webhooks to access our internal servers.
      |-NOTES
  }

  include profile::nginx

  profile::nginx::redirect { 'default':
    destination => "https://${canonical_fqdn}",
    default     => true,
    ssl         => true,
  }

  if $profile::server::params::fw {
    include profile::fw::https
  }

  $ssl_name = $facts['classification']['stage'] ? {
    'prod'  => 'webhook.puppet.com',
    default => 'wildcard.ops.puppetlabs.net',
  }

  class { 'webhook_proxy':
    cert_fqdn         => 'webhook.puppet.com',
    jenkins_fqdns     => [
      'jenkins-enterprise.delivery.puppetlabs.net',
      'cinext-jenkinsmaster-kub-test-1.delivery.puppetlabs.net',
      'cinext-jenkinsmaster-pipeline-prod-1.delivery.puppetlabs.net',
      'jenkins-cinext.delivery.puppetlabs.net',
      'jenkins-compose.delivery.puppetlabs.net',
      'jenkins-platform.delivery.puppetlabs.net',
      'jenkins-pipeline.delivery.puppetlabs.net',
      'jenkins-sre.delivery.puppetlabs.net',
      'jenkins.puppetlabs.com',
    ],
    endpoints         => [
      'https://cd4pe-test-1-backend.k8s.infracore.puppet.net/github/push',
      'https://cd4pe-prod-1-backend.k8s.infracore.puppet.net/github/push',
      'https://argocd-test.k8s.infracore.puppet.net/api/webhook', # Argo CD test
      'https://argocd-prod.k8s.infracore.puppet.net/api/webhook', # Argo CD prod
      'https://yoda.puppetlabs.com:8170/code-manager/v1/webhook/', # IT's PE
      'http://carls-cd4pe.p9.puppet.net:8000/github/push', # Carl's CD for PE instance
      'http://connect-beta.p9.puppet.net:8000/github/push', # Platform Services Puppet Connect instance
      'http://connect-dev-1.ops.puppetlabs.net:8000/github/push', # Forge Connect instance
      'http://cd4pe-prod-1.it.puppet.net:8000/github/push', # IT's CD4PE instance
      'http://cd4pe-beta.p9.puppet.net:8000/github/push', # CD4PE beta instance
      'http://cd4pe-beta.p9.puppet.net:8000/githubenterprise/push',
      'http://cd4pe-beta.p9.puppet.net:8000/bitbucket/webhook/push',
      'http://cd4pe-beta.p9.puppet.net:8000/bitbucketserver/push',
      'http://cd4pe-beta.p9.puppet.net:8000/gitlab/push',
      'http://cd4pe-beta.p9.puppet.net:8000/azuredevops/push',
    ],
    canonical_fqdn    => $canonical_fqdn,
    format_log        => 'logstash_json',
    server_cfg_append => {
      error_page             => '502 503 504 /puppet-private-maintenance.html',
      proxy_intercept_errors => 'on',
    },
    ssl_name          => $ssl_name,
  }

  nginx::resource::location { 'webhook __maintenance':
    server   => 'webhook',
    ssl      => true,
    ssl_only => true,
    location => '= /puppet-private-maintenance.html',
    internal => true,
    www_root => '/var/nginx/maintenance',
  }
}
