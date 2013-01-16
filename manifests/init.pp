class postgresql (
  $version  = $postgresql::params::default_version,
  $base_dir = $postgresql::params::default_base_dir,
  $cluster_name = $postgresql::params::cluster_name,
  $oom_adj  = 0,
) inherits postgresql::params {

  # Define variables
  case $::osfamily {
    'RedHat': {
      $data_dir = "${base_dir}/${cluster_name}"
      $conf_dir = $data_dir
      $pg_hba_conf_path = "${conf_dir}/pg_hba.conf"
      $postgresql_conf_path = "${conf_dir}/postgresql.conf"
      $ostype = 'redhat'
    }
    'Debian': {
      $data_dir = "${base_dir}/${version}/${cluster_name}"
      $conf_dir = "/etc/postgresql/${version}/${cluster_name}"
      $pg_hba_conf_path = "${conf_dir}/pg_hba.conf"
      $postgresql_conf_path = "${conf_dir}/postgresql.conf"
      $ostype = 'debian'
    }
    default: { fail "Unsupported OS family ${::osfamily}" }
  }

  # Checks
  validate_string($cluster_name, '$cluster_name must be a string')
  validate_re($base_dir, '^/', '$base_dir should be an absolute path')
  validate_re($conf_dir, '^/', '$conf_dir should be an absolute path')
  case $::osfamily {
    'Debian' : {
      case $::lsbdistcodename {
        'lenny': {
          validate_re($version, '^(8\.[34])$', "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!")
        }
        'squeeze': {
          validate_re($version, '^(8\.4|9\.0|9\.1)$', "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!")
        }
        'wheezy': {
          validate_re($version, '^9\.1$', "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!")
        }
        'lucid': {
          validate_re($version, '^8\.4$', "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!")
        }
        /^(precise|quantal)$/: {
          validate_re($version, '^9\.1$', "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!")
        }
        default: { fail "${::operatingsystem} ${::lsbdistcodename} is not yet supported!" }
      }
    }
    'RedHat' : {
      case $::lsbmajdistrelease {
        '6': {
          validate_re($version, '^8\.4$', "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!")
        }
        default: { fail "${::operatingsystem} ${::lsbdistrelease} is not yet supported!" }
      }
    }
    default: { fail "${::operatingsystem} is not yet supported!" }
  }

  # Include base
  include "postgresql::${ostype}"

  # Relationships
  Class["postgresql::${ostype}"] -> Postgresql::User <| |>
  Class["postgresql::${ostype}"] -> Postgresql::Database <| |>
}
