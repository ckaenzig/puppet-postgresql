/*

==Class: postgresql::debian

This class is dedicated to the common parts
shared by the different flavors of Debian

*/
class postgresql::debian inherits postgresql::base {

  include postgresql::client

  Package["postgresql"] {
    name   => "postgresql-${postgresql::version}",
    notify => Exec["drop initial cluster"],
  }

  User["postgres"] {
    groups => ['ssl-cert'],
  }

  File[$postgresql::base_dir] {
    mode => '0755',
  }

  package {[
    "postgresql-client-${postgresql::version}",
    "postgresql-common",
    "postgresql-contrib-${postgresql::version}"
    ]:
    ensure  => present,
    require => Package["postgresql"],
  }

  exec {"drop initial cluster":
    command     => "pg_dropcluster --stop ${postgresql::version} ${postgresql::cluster_name}",
    onlyif      => "test \$(su -c 'psql -lx' postgres |awk '/Encoding/ {printf tolower(\$3)}') = 'sql_asciisql_asciisql_ascii'",
    timeout     => 60,
    environment => "PWD=/",
    before      => Postgresql::Cluster[$postgresql::cluster_name],
  }

  postgresql::cluster {$postgresql::cluster_name:
    ensure  => present,
    version => $postgresql::version,
  }

  Postgresql::Conf {
    require => Postgresql::Cluster[$postgresql::cluster_name],
  }

  # A few default postgresql settings without which pg_dropcluster can't run.
  postgresql::conf {
    'data_directory':        value => "${postgresql::data_dir}";
    'hba_file':              value => "${postgresql::pg_hba_conf_path}";
    'ident_file':            value => "${postgresql::conf_dir}/pg_ident.conf";
    'external_pid_file':     value => "/var/run/postgresql/${postgresql::version}-main.pid";
    'unix_socket_directory': value => '/var/run/postgresql';
    'ssl':                   value => 'true';
  }

  if $postgresql::version == '8.3' {
    service {'postgresql':
      name      => "postgresql-${postgresql::version}",
      ensure    => running,
      enable    => true,
      hasstatus => true,
      require   => Package['postgresql'],
    }

    Exec['reload_postgresql'] {
      command => "/etc/init.d/postgresql-${postgresql::version} reload",
    }

  } else {
    service {'postgresql':
      ensure    => running,
      enable    => true,
      hasstatus => true,
      start     => "/etc/init.d/postgresql start ${postgresql::version}",
      status    => "/etc/init.d/postgresql status ${postgresql::version}",
      stop      => "/etc/init.d/postgresql stop ${postgresql::version}",
      restart   => "/etc/init.d/postgresql restart ${postgresql::version}",
      require   => Package['postgresql-common'],
    }

    Exec['reload_postgresql'] {
      command => "/etc/init.d/postgresql reload ${postgresql::version}",
    }
  }

  if ( $::lsbdistcodename == 'lenny' and $postgresql::version == '8.4' ) or
    ( $::lsbdistcodename == 'squeeze' and $postgresql::version =~ /^(9.0|9.1)$/ ) {
      apt::preferences {[
        'libpq5',
        "postgresql-${postgresql::version}",
        "postgresql-client-${postgresql::version}",
        'postgresql-common',
        'postgresql-client-common',
        "postgresql-contrib-${postgresql::version}"
        ]:
        pin      => "release a=${lsbdistcodename}-backports",
        priority => '1100',
      }
  }
}
