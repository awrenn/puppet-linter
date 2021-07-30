class profile::vagrant {
  ssh::allowgroup { 'vagrant': }
  sudo::allowgroup { 'vagrant': }
}
