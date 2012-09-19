/*

==Class: postgresql::debian

This class is dedicated to the common parts
shared by the different flavors of Debian

*/
class postgresql::debian inherits postgresql::base {

  include postgresql::params
  include postgresql::client

  Package["postgresql"] {
    name   => "postgresql-${postgresql::params::version}",
    notify => Exec["drop initial cluster"],
  }

  User["postgres"] {
    groups => ['ssl-cert'],
  }

  package {[
    "postgresql-client-${postgresql::params::version}",
    "postgresql-common",
    "postgresql-contrib-${postgresql::params::version}"
    ]:
    ensure  => present,
    require => Package["postgresql"],
  }

  exec {"drop initial cluster":
    command     => "pg_dropcluster --stop ${postgresql::params::version} main",
    onlyif      => "test \$(su -c 'psql -lx' postgres |awk '/Encoding/ {printf tolower(\$3)}') = 'sql_asciisql_asciisql_ascii'",
    timeout     => 60,
    environment => "PWD=/",
    before      => Postgresql::Cluster["main"],
  }

  postgresql::cluster {"main":
    ensure      => present,
    clustername => "main",
    version     => "${postgresql::params::version}",
    encoding    => "UTF8",
    data_dir    => "${postgresql::params::data_dir}",
    require     => [Package["postgresql"], Exec["drop initial cluster"]],
  }

  Postgresql::Conf {
    pgver  => "${postgresql::params::version}",
    before => Exec["drop initial cluster"],
  }

  # A few default postgresql settings without which pg_dropcluster can't run.
  postgresql::conf {
    'data_directory':        value => "${postgresql::params::data_dir}/${postgresql::params::version}/main";
    'hba_file':              value => "/etc/postgresql/${postgresql::params::version}/main/pg_hba.conf";
    'ident_file':            value => "/etc/postgresql/${postgresql::params::version}/main/pg_ident.conf";
    'external_pid_file':     value => "/var/run/postgresql/${postgresql::params::version}-main.pid";
    'unix_socket_directory': value => '/var/run/postgresql';
    'ssl':                   value => 'true';
  }

  if $postgresql::params::version == '8.3' {
    service {'postgresql':
      name      => "postgresql-${postgresql::params::version}",
      ensure    => running,
      enable    => true,
      hasstatus => true,
      require   => Package['postgresql'],
    }

    exec {"reload postgresql ${postgresql::params::version}":
      refreshonly => true,
      command     => "/etc/init.d/postgresql-${postgresql::params::version} reload",
    }

  } else {
    service {'postgresql':
      ensure    => running,
      enable    => true,
      hasstatus => true,
      start     => "/etc/init.d/postgresql start ${postgresql::params::version}",
      status    => "/etc/init.d/postgresql status ${postgresql::params::version}",
      stop      => "/etc/init.d/postgresql stop ${postgresql::params::version}",
      restart   => "/etc/init.d/postgresql restart ${postgresql::params::version}",
      require   => Package['postgresql-common'],
    }

    exec {"reload postgresql ${postgresql::params::version}":
      refreshonly => true,
      command     => "/etc/init.d/postgresql reload ${postgresql::params::version}",
    }
  }

  if ( $::lsbdistcodename == 'lenny' and $postgresql::params::version == '8.4' ) or
    ( $::lsbdistcodename == 'squeeze' and $postgresql::params::version =~ /^(9.0|9.1)$/ ) {
      apt::preferences {[
        'libpq5',
        "postgresql-${postgresql::params::version}",
        "postgresql-client-${postgresql::params::version}",
        'postgresql-common',
        'postgresql-client-common',
        "postgresql-contrib-${postgresql::params::version}"
        ]:
        pin      => "release a=${lsbdistcodename}-backports",
        priority => '1100',
      }
  }
}