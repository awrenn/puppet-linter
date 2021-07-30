# Include the appropriate class based on OS
#
# The root public keys are used in included classes. If the RSA key isn't set,
# then it will be explicitly deleted from authorized_keys.
class profile::os (
  String[1]           $root_ed25519_pub_key,
  Optional[String[1]] $root_rsa_pub_key = undef,
) {
  case $facts['kernel'] {
    'Linux':   { include profile::os::linux   }
    'Darwin':  { include profile::os::darwin  }
    'SunOS':   { include profile::os::solaris }
    'windows': { include profile::os::windows }
    default: {
      notify { "OS ${facts['kernel']} is not supported": }
    }
  }
}
