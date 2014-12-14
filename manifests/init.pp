# - user:
#   system user to act upon
class tbfisher (
  $user = 'vagrant',
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
    owner => $user,
    group => $user,
  }
  file { "${home}/.bashrc":
    ensure => 'file',
    source => 'puppet:///modules/tbfisher/bashrc',
    owner => $user,
    group => $user,
  }

  # Git
  file { "${home}/.gitconfig":
    ensure => 'file',
    owner => $user,
    group => $user,
  }
  ini_setting { 'git user name':
    ensure => present,
    path => "${home}/.gitconfig",
    section => 'user',
    setting => 'name',
    value => $git_user_name,
    require => File["${home}/.gitconfig"],
  }
  ini_setting { 'git user email':
    ensure => present,
    path => "${home}/.gitconfig",
    section => 'user',
    setting => 'email',
    value => $git_user_email,
    require => File["${home}/.gitconfig"],
  }
  ini_setting { 'git push default':
    ensure => present,
    path => "${home}/.gitconfig",
    section => 'push',
    setting => 'default',
    value => 'simple',
    require => File["${home}/.gitconfig"],
  }
  # git lg -- pretty printed git log
  # https://coderwall.com/p/euwpig
  ini_setting { 'git lg':
    ensure => present,
    path => "${home}/.gitconfig",
    section => 'alias',
    setting => 'lg',
    value => 'log --color --graph --pretty=format:\'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset\' --abbrev-commit',
    require => File["${home}/.gitconfig"],
  }
}