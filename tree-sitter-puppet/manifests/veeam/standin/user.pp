# Setup a target for backups to be exported to via ssh or scp
define profile::veeam::standin::user (
  String[1] $data_dir,
){
  Account::User <| title == $title |>
  ssh::allowgroup { $title: }

  file {
    "/backup-data/${data_dir}":
      ensure => directory,
      owner  => $title,
      group  => 'root',
      mode   => '0700',
    ;
    "/home/${title}/backup-data":
      ensure  => link,
      target  => "/backup-data/${data_dir}",
      require => User[$title],
    ;
  }
}

