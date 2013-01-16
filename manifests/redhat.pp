class postgresql::redhat inherits postgresql::base {

  # Checks
  validate_string($postgresql::cluster_name, '$postgresql::cluster_name must be a string')
  validate_re($postgresql::base_dir, '^/', '$postgresql::base_dir should be an absolute path')
  validate_re($postgresql::version, '^[0-9]\.[0-9]$', '$postgresql::version is not valid')

  File[$postgresql::base_dir] {
    mode => '0700',
  }

  file {'/etc/sysconfig/pgsql':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    content => "PG_OOM_ADJ=${postgresql::oom_adj}\n",
  }

  postgresql::cluster {$postgresql::cluster_name:
    ensure  => present,
    version => $postgresql::version,
    require => Package['postgresql'],
  }

  service {'postgresql':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => [
      Postgresql::Cluster[$postgresql::cluster_name],
      File['/etc/sysconfig/pgsql'],
    ]
  }

}
