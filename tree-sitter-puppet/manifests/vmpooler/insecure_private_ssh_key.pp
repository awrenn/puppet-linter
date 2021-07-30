# @sumary Adds the insecure private key for vmpooler vms to a give user
#
# Adds the insecure private key for vmpooler vms to a give user
# It is the responsibility of whoever is using this type to add any needed
# require statements as part of its declaration in a manifest.
#
# @example
#   profile::vmpooler::insecure_private_ssh_key { 'pooler key for pipelines agent':
#     user      => 'distelli',
#     user_home => '/home/distelli',
#     require   => Class['Pipelines::Agent'],
#   }
#
# @param user
#   The user name of the account who will own the ssh key
# @param user_home
#   The home directory of the user you wish to add the key to
# @param key_name
#   The name of the file in which to place the key content
# @param content
#   The text of the private key file
define profile::vmpooler::insecure_private_ssh_key (
  String[1] $user,
  Stdlib::Absolutepath $user_home,
  String[1] $key_name = 'id_rsa-acceptance',
  Sensitive[String[1]] $content = Sensitive(lookup('vmpooler::insecure_private_ssh_key')),
) {
  file { "${user_home}/.ssh/${key_name}":
    ensure  => file,
    owner   => $user,
    mode    => '0600',
    content => node_encrypt::secret($content),
  }
}
