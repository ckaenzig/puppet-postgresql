/*

==Definition: postgresql::cluster

Create a new PostgreSQL cluster

*/
define postgresql::cluster (
  $ensure,
  $encoding = 'UTF8'
) {

  include postgresql::params

  case $ensure {
    present: {

      file {$name:
        ensure  => directory,
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0755',
        require => [Package['postgresql'], User['postgres']],
      }

      file {"${postgresql::params::conf_dir}/server.key":
        ensure => link,
        target => "${postgresql::params::conf_dir}/ssl-cert-snakeoil.key",
      }

      file {"${postgresql::params::conf_dir}/server.crt":
        ensure => link,
        target => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
      }

      exec {"pg_createcluster --start -e ${encoding} -u ${uid} -g ${gid} -d ${postgresql::params::data_dir} ${postgresql::params::version} ${postgresql::params::cluster_name}":
        unless  => "pg_lsclusters -h | awk '{ print \$1,\$2; }' | egrep '^${postgresql::params::version} ${postgresql::params::cluster_name}\$'",
        require => File[$name],
      }

    }

    absent: {
      exec {"pg_dropcluster --stop ${postgresql::params::version} ${postgresql::params::cluster_name}":
        onlyif  => "pg_lsclusters -h | awk '{ print \$1,\$2,\$6; }' | egrep '^${postgresql::params::version} ${postgresql::params::cluster_name} ${postgresql::params::data_dir}\$'",
        require => Service['postgresql'],
      }
    }

    default: { fail "Unknown ${ensure} value for ensure" }
  }
}
