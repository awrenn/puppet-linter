class profile::aws::cloudwatch {
  include cloudwatch
  cloudwatch::log {'/var/log/messages': }
  cloudwatch::log {'/var/log/syslog': }
  cloudwatch::log {'/var/log/kern.log': }
  cloudwatch::log {'/var/log/auth.log': }
}

