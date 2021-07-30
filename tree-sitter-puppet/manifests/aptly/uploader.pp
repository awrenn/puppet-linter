# Access to upload packages to aptly via scp
define profile::aptly::uploader (
  Array[String[1], 1]               $allowed_names,
  Pattern[/\A[A-Za-z0-9-]+\Z/]      $keytype,
  Pattern[/\A[A-Za-z0-9+\/]+=*\Z/]  $key,
  Array[String[1], 1]               $repos,
  Pattern[/\A[^ \t\n'"\\#]+\Z/]     $key_title = $title,
  Array[String[1]]                  $on_success = [],
) {
  include profile::aptly

  $arguments = [
      $on_success.map |$c| { ['--on-success', $c] },
      $repos.map |$r| { ['--repo', $r] },
      $allowed_names,
    ].shellquote()
    # Replace " and \ with \" and \\:
    .regsubst('(["\\\\])', '\\\\\\0', 'G')

  ssh_authorized_key { "uploader:${key_title}":
    ensure  => present,
    user    => 'aptly',
    type    => $keytype,
    key     => $key,
    options => [
      "command=\"/usr/local/bin/aptly-ssh-handler.py ${arguments}\"",
      'no-port-forwarding',
      'no-X11-forwarding',
      'no-pty',
    ],
  }
}
