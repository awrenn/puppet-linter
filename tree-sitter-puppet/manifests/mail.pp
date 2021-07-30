##
#
class profile::mail {

  case $kernel {
    'Darwin': { }
    'SunOS': {
      service { ['network/sendmail-client:default', 'network/smtp:sendmail']:
        ensure => stopped,
        enable => false,
      }
    }
    'windows': {

    }
    default: {
      include postfix
      include postfix::mboxcheck # let me know that we have crap mail.
    }
  }
}
