class profile::packages::shells {
  include bash
  unless $facts['kernel'] == 'Darwin' {
    include zsh
  }
}
