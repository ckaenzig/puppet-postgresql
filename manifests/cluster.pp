/*

==Definition: postgresql::cluster

Create a new PostgreSQL cluster

*/
define postgresql::cluster (
  $version,
  $ensure   = 'present',
  $encoding = 'UTF8'
) {

  case $ensure {
    present: {

      case $::operatingsystem {
        Debian,Ubuntu: {
          file {"${postgresql::base_dir}/${version}/${name}/server.key":
            ensure  => link,
            target  => '/etc/ssl/private/ssl-cert-snakeoil.key',
            require => Exec["pg_createcluster_${version}_${name}"],
          }

          file {"${postgresql::base_dir}/${version}/${name}/server.crt":
            ensure  => link,
            target  => '/etc/ssl/certs/ssl-cert-snakeoil.pem',
            require => Exec["pg_createcluster_${version}_${name}"],
          }

          exec {"pg_createcluster_${version}_${name}":
            command => "pg_createcluster --start -e ${encoding} -u postgres -g postgres -d ${postgresql::base_dir}/${version}/${name} ${version} ${name}",
            unless  => "pg_lsclusters -h | awk '{ print \$1,\$2; }' | egrep '^${version} ${name}\$'",
            require => File[$postgresql::base_dir],
          }
        }
        Redhat,CentOS: {
          exec {"pg_createcluster_${version}_${name}":
            command => "initdb --pgdata='${postgresql::base_dir}/${name}' --encoding='${encoding}' --auth='ident'",
            user    => 'postgres',
            unless  => "/usr/bin/test -f ${postgresql::base_dir}/${name}/PG_VERSION",
            require => File[$postgresql::base_dir],
          }
        }
      }

    }

    absent: {
      case $::operatingsystem {
        Debian,Ubuntu: {
          exec {"pg_dropcluster --stop ${version} ${name}":
            onlyif  => "pg_lsclusters -h | awk '{ print \$1,\$2,\$6; }' | egrep '^${version} ${name} ${postgresql::base_dir}/${version}/${name}\$'",
            require => Service['postgresql'],
          }
        }
        default: { fail 'not yet implemented!' }
      }
    }

    default: { fail "Unknown ${ensure} value for ensure" }
  }
}
