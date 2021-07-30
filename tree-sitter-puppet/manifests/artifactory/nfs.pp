class profile::artifactory::nfs {
  profile_metadata::service { $title:
    human_name => 'Artifactory NFS',
    owner_uid  => 'eric.griswold',
    team       => re,
    end_users  => ['org-products@puppet.com'],
    doc_urls   => [
      'https://confluence.puppetlabs.com/display/RE/Artifactory+Basics',
    ],
  }

}
