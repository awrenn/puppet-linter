class profile::ghost::dataingest {
  profile_metadata::service { $title:
    human_name        => 'Ghost Data Ingest App',
    owner_uid         => 'gene.liverman',
    team              => dio,
    end_users         => ['notify-infracore@puppet.com'],
    escalation_period => 'global-workhours',
    downtime_impact   => "Data from PE is not being shipped to Ghost's data analytics service.",
  }

  include profile::access::ghost
}
