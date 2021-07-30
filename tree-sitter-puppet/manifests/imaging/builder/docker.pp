class profile::imaging::builder::docker {
  class { 'docker':
    repo_opt => '',
  }

  # Configuring this in the docker class causes duplicate resources problems.
  # This just adds the docker group to the jenkins user.
  User <| title == 'jenkins' |> {
    groups +> ['docker']
  }
}
