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
  # git lg -- pretty printed git log
  # https://coderwall.com/p/euwpig
  ini_setting { 'git lg':
    ensure  => present,
    path    => $git_config,
    section => 'alias',
    setting => 'lg',
    value   => 'log --color --graph --pretty=format:\'%Cred%h%Creset \
-%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\' \
--abbrev-commit',
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
