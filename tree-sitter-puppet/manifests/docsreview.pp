class profile::docsreview {
  $application = 'docsreview'

  include profile::ssl::ops
  include profile::fw::http
  include profile::fw::https

  Account::User <| title == 'docsreview' |>
  Account::User <| title == 'docsdeploy' |>

  if $::profile::server::backups {
    include profile::docsreview::backup
  }
}
