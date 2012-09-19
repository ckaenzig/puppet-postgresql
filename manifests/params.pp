class postgresql::params {

  case $postgresql_version {
    '': {
      case $::operatingsystem {
        /^(RedHat|CentOS)$/ : {
          case $::lsbmajdistrelease {
            '6'    : { $version = '8.4' }
            default: { fail "${::lsbmajdistrelease} is not yet supported!" }
          }
        }
        /^(Debian|Ubuntu)$/ : {
          case $::lsbdistcodename {
            'lenny':   { $version = '8.3' }
            'squeeze': { $version = '8.4' }
            'lucid':   { $version = '8.4' }
            'precise': { $version = '9.1' }
            default:   { fail "${::operatingsystem} ${::lsbdistcodename} is not yet supported!"}
          }
        }
        default: { fail "${::operatingsystem} is not yet supported!" }
      }
    }
    /^(8.3|8.4|9.0|9.1)$/ : {
      case $::operatingsystem {
        /^(Debian|Ubuntu)$/ : {
          case $::lsbdistcodename {
            'lenny': {
              if $postgresql_version == '8.3' {
                $version = $postgresql_version
              } else {
                fail "version ${postgresql_version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!"
              }
            }
            'squeeze': {
              if $postgresql_version =~ /^(8.4|9.0|9.1)$/ {
                $version = $postgresql_version
              } else {
                fail "version ${postgresql_version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!"
              }
            }
            'lucid': {
              if $postgresql_version == '8.4' {
                $version = $postgresql_version
              } else {
                fail "version ${postgresql_version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!"
              }
            }
            'precise': {
              if $postgresql_version == '9.1' {
                $version = $postgresql_version
              } else {
                fail "version ${postgresql_version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!"
              }
            }
            default: { fail "${::operatingsystem} ${::lsbdistcodename} is not yet supported!" }
          }
        }
        default: { fail "${::operatingsystem} is not yet supported!" }
      }
    }
    default: { fail "PostgreSQL ${postgresql_version} is not supported by this module!" }
  }

  $data_dir = $postgresql_data_dir ? {
    '' => $operatingsystem ? {
      /^(RedHat|CentOS)$/ => '/var/lib/pgsql',
      /^(Debian|Ubuntu)$/ => '/var/lib/postgresql',
    },
    default => $postgresql_data_dir,
  }

}
