# Class: profile::cygwin
#
class profile::cygwin {
  include cygwin

  windows_env { 'PATH=C:\Cygwin64\bin':
    type => 'REG_EXPAND_SZ',
  }
}
