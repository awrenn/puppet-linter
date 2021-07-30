##
#
class profile::delivery::sun (
  $user = 'jenkins',
) {
  Account::User <| title == $user |> { home => "/home/${user}" }
  ssh::allowgroup { $user: }

  ssh_authorized_key { $user:
    user => $user,
    type => 'ssh-rsa',
    key  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAsMvODgIqL1NoUgP65qmgf0sJjQy78QdA5rHw9tIwK5KstVSh+0w4TLHJq8Jz8E4UeXhx0NioP3kE3otjCC8kSM5y99QOs4qQh7q6cLN9hQpXMQUD9UnJMP0b5agd0PdErH0ML9hnWfsZX707v31VSIbco+X6Kg9wN8WJhlTXgbbrJTUIPnMzNXrN7Z5/jY6Vss7NTCVI7OxUbIna37l5y8s4jxViaXjoVEXP8e4QtTX8p0BYc2vgerI04ZilhbIe4KEcHiR+n/GUr6MmkY5qtLum/7IZLHbHfWha1q7VaPnz/CHmlDySxxq4sF81N4x2V7d0+x8/wNZx2d+duJmV0Q==',
  }

  # this needs to be deleted once nspooler is updated to not connect as root
  # per Matt Kirby 7 March 2019
  ssh_authorized_key { "${user}_nspooler_key":
    user => 'root',
    type => 'ssh-rsa',
    key  => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAsMvODgIqL1NoUgP65qmgf0sJjQy78QdA5rHw9tIwK5KstVSh+0w4TLHJq8Jz8E4UeXhx0NioP3kE3otjCC8kSM5y99QOs4qQh7q6cLN9hQpXMQUD9UnJMP0b5agd0PdErH0ML9hnWfsZX707v31VSIbco+X6Kg9wN8WJhlTXgbbrJTUIPnMzNXrN7Z5/jY6Vss7NTCVI7OxUbIna37l5y8s4jxViaXjoVEXP8e4QtTX8p0BYc2vgerI04ZilhbIe4KEcHiR+n/GUr6MmkY5qtLum/7IZLHbHfWha1q7VaPnz/CHmlDySxxq4sF81N4x2V7d0+x8/wNZx2d+duJmV0Q==',
  }

  sudo::entry { 'rollback LDOM':
    entry => "${user} ALL=(ALL) NOPASSWD:/export/home/jenkins/rollback.sh",
  }
}

