# This class gives the forge team full sudo to a server.
class profile::forge::sudo {

  sudo::entry {
    'Forge admins: full sudo':
      entry => '%forge-admins ALL=(ALL) NOPASSWD: ALL';
  }
}
