# Allow access for the TSE team
class profile::sailseng {
  Group         <| title == 'sailseng' |>
  Account::User <| groups == 'sailseng' |>

  ssh::allowgroup  { 'sailseng': }
  sudo::allowgroup { 'sailseng': }
}
