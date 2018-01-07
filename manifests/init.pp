# == Class: webook
#
# This will install and configure the webhook for git webhooks
# so it will run an r10k deploy * action
#
# === Requirements
#
# No requirements.
#
# - puppetlabs-operations/puppet-bundler
#
# === Parameters
#
# [*webhook_home*]
# This is the directory where all stuff of
# this webhook is installed
#
# [*webhook_port*]
# On which port it is listening for requests
#
# [*webhook_owner*]
# The owner of this service/script
#
# [*webhook_group*]
# The group of this service/script
#
# [*repo_puppetfile*]
# The name of the repository where the 'Puppetfile'
# is stored.
#
# [*repo_hieradata*]
# The name of the repository where the 'hieradata'
# is stored.
#
# [*ruby_dev*]
# The package name of ruby-devel (or when debian: ruby-dev)
#
# [*mco*]
# Enables mco. Defaults to false (lowercase). See params.pp for explanation.
# [*mco_user*]
# The user being utilized to invoke mco r10k. Defaults to mcollective-user
#
# === Example
#
#  class { 'webhook':
#    webhook_port    => '8088',
#    repo_puppetfile => "puppetfilerepo",
#    repo_hieradata  => "puppethieradata",
#  }
#
# === Authors
#
# Author Name: ikben@werner-dijkerman.nl
#
# === Copyright
#
# Copyright 2014 Werner Dijkerman
#
class webhook (
  $webhook_home    = '/opt/webhook',
  $webhook_bind    = '0.0.0.0',
  $webhook_port    = '8088',
  $webhook_owner   = 'root',
  $webhook_group   = 'root',
  $mco             = false,
  $mco_user        = 'mcollective-user',
  $repo_puppetfile = undef,
  $repo_hieradata  = undef,
  $ruby_dev        = 'ruby-dev',
  $ruby_prefix     = '/usr/local/rvm/wrappers/ruby-2.2.6'
) {

  file { "${webhook_home}":
    ensure  => directory,
    owner   => $webhook_owner,
    group   => $webhook_group,
    mode    => '0755',
  }

  file { "${webhook_home}/config.ru":
    ensure  => present,
    owner   => $webhook_owner,
    group   => $webhook_group,
    mode    => '0755',
    source  => 'puppet:///modules/webhook/config.ru',
  }

  file { "${webhook_home}/webhook_config.json":
    ensure  => present,
    owner   => $webhook_owner,
    group   => $webhook_group,
    mode    => '0644',
    source  => 'puppet:///modules/webhook/webhook_config.json',
    notify  => Service['webhook'],
  }

  file { "${webhook_home}/Gemfile":
    ensure  => present,
    owner   => $webhook_owner,
    group   => $webhook_group,
    mode    => '0755',
    source  => 'puppet:///modules/webhook/Gemfile',
    notify  => Exec['run_bundler'],
  }

  exec { 'run_bundler':
    command     => "$ruby_path/bundle install --path vendor/bundle",
    cwd         => $webhook_home,
    refreshonly => true,
  }

  file { "${webhook_home}/log":
    ensure  => directory,
    owner   => $webhook_owner,
    group   => $webhook_group,
    mode    => '0755',
  }

  file { "${webhook_home}/webhook.rb":
    ensure  => present,
    owner   => $webhook_owner,
    group   => $webhook_group,
    mode    => '0755',
    content => template('webhook/webhook.rb'),
    notify  => Service['webhook'],
  }

  file { '/etc/systemd/system/webhook.service':
    ensure  => present,
    mode    => '0775',
    content => template('webhook/service.systemd.erb'),
    notify  => Service['webhook'],
  }

  service { 'webhook':
    ensure     => running,
    hasstatus  => true,
    enable     => true,
    hasrestart => true,
  }
}

