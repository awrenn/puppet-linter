# Manage the value of inotify watches
#
# For a shared machine running docker the default value of 8192 can be too limited, causing an
# error to be reported “java.io.IOException: User limit of inotify watches reached”
# Adjusted per request in https://tickets.puppetlabs.com/browse/DIO-421
class profile::os::linux::redhat::inotify_watches (
  Optional[Integer] $max_watches = undef,
) {
  if $max_watches {
    sysctl::value { 'fs.inotify.max_user_watches':
      value => $max_watches,
    }
  }
}
