class profile::os::solaris::system_conf (
  $nfs_max_threads    = $facts['processors']['count'] * 2,
  $nfs_async_clusters = $facts['processors']['count'],
  $system_conf        = '/etc/system',
  $user_reserve_hint  = undef
) {

  File_line {
    ensure => present,
    path   => $system_conf,
  }

  file_line {
    'nfs3_max_threads':
      line  => "set nfs:nfs3_max_threads = ${nfs_max_threads}",
      match => '.*nfs3_m.*';
    'nfs4_max_threads':
      line  => "set nfs:nfs4_max_threads = ${nfs_max_threads}",
      match => '.*nfs4_m.*';
    'nfs3_async_clusters':
      line  => "set nfs:nfs3_async_clusters = ${nfs_async_clusters}",
      match => '.*nfs3_a.*';
    'nfs4_async_clusters':
      line  => "set nfs:nfs4_async_clusters = ${nfs_async_clusters}",
      match => '.*nfs4_a.*',
  }

  if $user_reserve_hint {
    file_line { 'user_reserve_memory':
      line  => "set user_reserve_hint_pct = ${user_reserve_hint}",
      match => 'set user_reserve_hint_pct = \d+',
    }
  }
}
