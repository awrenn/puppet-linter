# Class: profile::jenkins::usage::docker
# Based on but but smaller than imaging.pp
#
class profile::jenkins::usage::docker {
  include profile::imaging::builder::docker
}
