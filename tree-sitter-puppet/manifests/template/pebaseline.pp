# This profile pulls in settings we wish to include in virtual machine templates
class profile::template::pebaseline {
  ['release', 'sailseng', 'support',].each |$tag_group| {
    Account::User <| groups == $tag_group |>
    Group         <| title == $tag_group |>

    ssh::allowgroup { $tag_group: }
    sudo::allowgroup { $tag_group: }
  }
}
