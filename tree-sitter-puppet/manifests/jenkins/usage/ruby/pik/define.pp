# Define: profile::jenkins::usage::ruby::pik::define
# Defined type to reduce code duplication in profile::jenkins::usage::ruby::pik.
#
# Params:
#   - ruby_ver:         the ruby version string (tag) only, e.g. "2.1.5.0-x86",
#                       as it has been tagged in the puppet-win32-ruby repo.
#                       Defaults to $title.
#   - ruby_name:        a human-readable name for the Ruby, e.g.
#                       "ruby-2.1.5.0-x86". Defaults to "ruby-${title}"
#   - ruby_desc:        a human-readable description for the Ruby, e.g.
#                       "Ruby 2.1.5.0-x86 (puppetlabs)" that will appear when
#                       running `pik info`. Defaults to
#                       "Ruby ${title} (puppetlabs)". To also get a patch
#                       level, or other info about the Ruby that was added at
#                       build time, consider adding `ruby -v` to a CI job.
#   - ruby_dist_url:    the URL to download the puppet-win32-ruby tagged Zip
#                       archive from GitHub
#   - ruby_dist_dest:   the location to stage the aforementioned zip archive
#   - ruby_install_dir: the path created when extracting the zip archive. This
#                       is *not* arbitrary; it needs to be the directory
#                       structure that exists within the Zip archive.
#   - pik_config:       the path to the Pik configuration file; defaults to
#                       "c:/tools/pik/config.yml" because that's where
#                       Chocolatey puts it. Note: the 'concat' resource that
#                       sets up the config file is defined in Class['pik'];
#                       only the fragments are managed and created here.
#   - pik_config_order: the order this ruby version should appear in the pik
#                       configuration file.  Defaults to '10', which is the
#                       default for the concat module.
#
define profile::jenkins::usage::ruby::pik::define (
  $ruby_ver         = $title,
  $ruby_name        = "ruby-${title}",
  $ruby_desc        = "Ruby ${title} (puppetlabs)",
  $ruby_dist_url    = "https://github.com/puppetlabs/puppet-win32-ruby/archive/${title}.zip",
  $ruby_dist_dest   = "c:/jenkins/ruby-${title}.zip",
  $ruby_install_dir = "c:/puppet-win32-ruby-${title}",
  $pik_config       = 'c:/tools/pik/config.yml',
  $pik_config_order = '10',
) {

  Exec { path => "c:/programdata/chocolatey/bin:${::path}" }

  # A lot of things go wrong if we don't use --no-check-certificate.
  # I don't particularly like this hack. -- roger, 2015-02-24
  exec { "download-${ruby_name}":
    command => "wget --no-check-certificate ${ruby_dist_url} -O ${ruby_dist_dest}",
    creates => $ruby_dist_dest,
  }

  # Extract Rubies to their final resting place
  $cwd = split($ruby_install_dir, '/')

  exec { "extract-${ruby_name}":
    command => "7za x -y ${ruby_dist_dest}",
    cwd     => "${cwd[0]}/",
    creates => $ruby_install_dir,
    require => Exec["download-${ruby_name}"],
  }

  concat::fragment { "concat-${ruby_name}":
    target  => $pik_config,
    content => "\"[ruby-]${ruby_ver}\": \r\n  :path: !ruby/object:Pathname \r\n    path: ${ruby_install_dir}/ruby/bin\r\n  :version: |\r\n    ${ruby_desc}\r\n\r\n",
    order   => $pik_config_order,
  }
}
