# Class: profile::jenkins::master::plugins
# This class maintains the resources to install/upgrade Jenkins plugins. It is
# a base list; Jenkins admins will still be able to install plugins via the
# usual Jenkins Update Center.
#
# A complete list of plugins can be found at
#   https://updates.jenkins-ci.org/download/plugins/
#
class profile::jenkins::master::plugins {

  ###########################################################################
  # CORE PLUGINS
  # ------------
  # Alphabetical list of plugins core to the way Jenkins functions
  ###########################################################################

  jenkins::plugin { 'audit2db':                }
  jenkins::plugin { 'credentials':             }
  jenkins::plugin { 'jquery':                  }
  jenkins::plugin { 'job-import-plugin':       }
  jenkins::plugin { 'ldap':                    }
  jenkins::plugin { 'mailer':                  }
  jenkins::plugin { 'metadata':                }
  jenkins::plugin { 'scm-api':                 }
  jenkins::plugin { 'ssh-credentials':         }
  jenkins::plugin { 'ssh-slaves':              }
  jenkins::plugin { 'swarm':                   }
  jenkins::plugin { 'token-macro':             }


  ###########################################################################
  # JOB PLUGINS
  # -----------
  # Alphabetical list of plugins core to managing jobs
  ###########################################################################

  jenkins::plugin { 'ansicolor':                    }
  jenkins::plugin { 'clone-workspace-scm':          }
  jenkins::plugin { 'copyartifact':                 }
  jenkins::plugin { 'dynamic-axis':                 }
  jenkins::plugin { 'git':                          }
  jenkins::plugin { 'git-client':                   }
  jenkins::plugin { 'github':                       }
  jenkins::plugin { 'github-api':                   }
  jenkins::plugin { 'greenballs':                   }
  jenkins::plugin { 'jenkins-multijob-plugin':      }
  jenkins::plugin { 'jobConfigHistory':             }
  jenkins::plugin { 'parameterized-trigger':        }
  jenkins::plugin { 'ws-cleanup':                   }


  ###########################################################################
  # REPORTING PLUGINS
  # -----------------
  # Alphabetical list of plugins that aid in reporting Jenkins results
  ###########################################################################

  jenkins::plugin { 'build-failure-analyzer':       }
  jenkins::plugin { 'build-monitor-plugin':         }
  jenkins::plugin { 'build-publisher':              }
  jenkins::plugin { 'database':                     }
  jenkins::plugin { 'database-postgresql':          }
  jenkins::plugin { 'delivery-pipeline-plugin':     }
  jenkins::plugin { 'disk-usage':                   }
  jenkins::plugin { 'dropdown-viewstabbar-plugin':  }
  jenkins::plugin { 'email-ext':                    }
  jenkins::plugin { 'embeddable-build-status':      }
  jenkins::plugin { 'ghprb':                        }
  jenkins::plugin { 'hipchat':                      }
  jenkins::plugin { 'htmlpublisher':                }
  jenkins::plugin { 'job-parameter-summary':        }
  jenkins::plugin { 'mttr':                         }
  jenkins::plugin { 'multi-module-tests-publisher': }
  jenkins::plugin { 'nested-view':                  }
  jenkins::plugin { 'test-stability':               }
}
