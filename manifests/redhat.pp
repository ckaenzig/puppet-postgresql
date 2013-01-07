class postgresql::redhat inherits postgresql::base {

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
