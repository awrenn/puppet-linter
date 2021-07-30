# Generate an SSH key pair to grant access to an Aptly repo
#
# This is used on a client machine; the repo host uses
# profile::aptly::uploader::collector to query these records and grant access.
#
# $allowed_names - Globs matching package names the client may upload
# $repos - An array of repos to allow access to
# $key_title - A title to identify the SSH key
# $user - The user to create the SSH key for
# $target - The identifier for the repo host to grant access to
# $key_path - The path to the user's SSH private key
define profile::aptly::uploader::client (
  Array[String[1], 1] $allowed_names,
  Variant[Enum['*'], Array[String[1], 1]] $repos = '*',
  Pattern[/\A[^ \t\n'"\\#]+\Z/] $key_title = $title,
  String[1] $user = $title.split('@')[0],
  String[1] $target = $title.split('@')[1],
  Pattern[/\A\//] $key_path = "/home/${user}/.ssh/id_rsa",
) {
  ssh::key { $key_title:
    user               => $user,
    key_path           => $key_path,
    manage_known_hosts => false,
  }
}
