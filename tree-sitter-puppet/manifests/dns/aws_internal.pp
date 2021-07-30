class profile::dns::aws_internal (
  Optional[Array[String[1]]] $masters = undef,
  String[1] $internal_aws_zone        = 'us-west-2.compute.internal',
) {
  if $masters {
    bind::zone { $internal_aws_zone:
      type         => 'forward',
      masters      => $masters,
      allow_update => 'key "dhcp_updater"',
      require      => Bind::Key['dhcp_updater'],
    }
  }
}
