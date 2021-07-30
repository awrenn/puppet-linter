# This class downloads the OpenTelemetry JAR for use by PE servers
class profile::pe::otel (
  String[1] $otel_version = 'v1.1.0',
){
  file { '/opt/puppetlabs/otel':
    ensure => directory,
  }

  $notifies = $facts['classification']['function'] ? {
    'master'   => [
      Exec[
        'pe-console-services service full restart',
        'pe-orchestration-services service full restart',
        'pe-puppetdb service full restart',
        'pe-puppetserver service full restart',
      ],
    ],
    'compiler' => [
      Exec[
        'pe-puppetdb service full restart',
        'pe-puppetserver service full restart',
      ],
    ],
    default => undef,
  }

  archive { '/opt/puppetlabs/otel/opentelemetry-javaagent-all.jar':
    ensure  => present,
    source  => "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/${otel_version}/opentelemetry-javaagent-all.jar",
    user    => 0,
    group   => 0,
    require => File['/opt/puppetlabs/otel'],
    notify  => $notifies,
  }
}
