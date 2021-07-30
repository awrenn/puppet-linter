##
#
class profile::repo::repos {
  profile::repo::repo { 'deployer': }
  profile::repo::repo { 'example': }
  profile::repo::repo { 'puppetenterprise': }
  profile::repo::repo { 'sysops-openstack/7/x86_64': }
  profile::repo::repo { 'sysops-diamond/6/x86_64': }
  profile::repo::repo { 'sysops-diamond/7/x86_64': }
  profile::repo::repo { 'sysops-checks/7/x86_64': }
}
