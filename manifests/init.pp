# - user:
#   system user to act upon
# - git_user_name
#   git config user.name
# - git_user_email
#   git config user.email
class tbfisher (
  $user,
  $git_user_name,
  $git_user_email,
) {
  case $user {
    'root': { $home = '/root' }
    default: { $home = "/home/${user}"}
  }

  if ! defined(Package['pv']) {
    package { 'pv': }
  }

  # jq
  wget::fetch { 'http://stedolan.github.io/jq/download/linux64/jq':
    destination => '/usr/local/bin/jq',
  } ~>
  file { '/usr/local/bin/jq':
    ensure => file,
    mode   => '0755',
  }

  # Shell
  file { "${home}/.bash_profile":
    ensure => 'file',
    source => 'puppet:///modules/tbfisher/bash_profile',
    owner  => $user,
    group  => $user,
  }
  file { "${home}/.bashrc":
    ensure => 'file',
    source => 'puppet:///modules/tbfisher/bashrc',
    owner  => $user,
    group  => $user,
  }

  # Git
  $git_config = "${home}/.gitconfig"
  file { $git_config:
    ensure => 'file',
    owner  => $user,
    group  => $user,
  }
  ini_setting { 'git user name':
    ensure  => present,
    path    => $git_config,
    section => 'user',
    setting => 'name',
    value   => $git_user_name,
    require => File[$git_config],
  }
  ini_setting { 'git user email':
    ensure  => present,
    path    => $git_config,
    section => 'user',
    setting => 'email',
    value   => $git_user_email,
    require => File[$git_config],
  }
  ini_setting { 'git push default':
    ensure  => present,
    path    => $git_config,
    section => 'push',
    setting => 'default',
    value   => 'simple',
    require => File[$git_config],
  }
}

# nfs
class tbfisher::nfs (
) {

  include tbfisher

  package { [
      'nfs-kernel-server',
      'nfs-common',
      'rpcbind',
    ] :
    ensure => 'installed'
  }

  service { 'nfs-kernel-server':
    ensure  => running,
    enable  => true,
    require => Package['nfs-kernel-server'],
  }

  $home = $tbfisher::home
  $exports = "\
/var/www *(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
${home} *(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
"

  file { '/etc/exports':
    require => Package['nfs-kernel-server'],
    notify  => Service['nfs-kernel-server'],
    content => $exports,
  }
}
