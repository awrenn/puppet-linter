# Class: profile::jenkins::usage::imaging
#
class profile::jenkins::usage::imaging {
  include profile::imaging::builder::docker
  include profile::imaging::builder::libvirt
  include profile::imaging::builder::nfs
  include profile::imaging::builder::packer
  include profile::imaging::builder::virtualbox
}
