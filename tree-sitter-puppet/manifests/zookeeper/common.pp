class profile::zookeeper::common(
  $cluster_name = "${facts['classification']['group']}-${facts['classification']['function']}-${facts['classification']['stage']}",
){
  $pdbquery_zookeepers = puppetdb_query("inventory[certname] { facts.classification.group = '${facts['classification']['group']}' and facts.classification.stage = '${facts['classification']['stage']}' and resources { type = 'Class' and title = 'Profile::Zookeeper' } }")
}
