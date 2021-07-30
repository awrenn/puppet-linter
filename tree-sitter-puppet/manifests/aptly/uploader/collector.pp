# Collect public keys from clients configured to upload to this repo
#
# The title of this resource should be used in the `$target` parameter on
# `profile::aptly::uploader::client`.
#
# $all_repos - An array of all the repos to use if the client passes '*'
# $on_success - Scripts to run after an upload is complete
# $fact_filter - Query to select nodes to collect clients from
define profile::aptly::uploader::collector (
  Array[String[1], 1] $all_repos,
  Array[String[1]] $on_success = [],
  Variant[String[1], Boolean] $fact_filter = "facts.classification.stage = '${facts['classification']['stage']}'",
) {
  $extra_conditions = $fact_filter ? {
    false   => '',
    true    => fail('profile::aptly::uploader::collector::fact_filter must either be false or a string'),
    default => "and certname in inventory[certname] { ${fact_filter} }",
  }

  $clients = puppetdb_query("resources {
    type              = 'Profile::Aptly::Uploader::Client' and
    parameters.target = '${title}'
    ${extra_conditions}
  }")

  $clients.each |$client| {
    $client_certname = $client['certname']
    $key_title       = $client['parameters']['key_title']
    $fact            = "ssh_public_key_${key_title}_rsa"
    $repos           = $client['parameters']['repos'] ? {
      '*'     => $all_repos,
      default => $client['parameters']['repos'],
    }

    $public_keys = (puppetdb_query("inventory {
      certname = '${client_certname}'
    }").map |$value| { $value['facts'][$fact] }).unique

    if $public_keys.size() > 1 {
      fail("More than one ${fact} found for certname ${client_certname}")
    } elsif $public_keys.size() == 1 {
      [$key_type, $key, $comment] = $public_keys[0].split(' ')

      profile::aptly::uploader { [$client_certname, $key_title].join(':'):
        repos         => $repos,
        allowed_names => $client['parameters']['allowed_names'],
        on_success    => $on_success,
        keytype       => $key_type,
        key           => $key,
      }
    }
  }
}
