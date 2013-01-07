class postgresql (
  version  = $postgresql::params::default_version,
  base_dir = $postgresql::params::default_base_dir,
  oom_adj  = 0,
) inherits postgresql::params {

  case $::osfamily {
    'Debian' : {
      case $::lsbdistcodename {
        'lenny': {
          if $version !~ /^(8.[34])$/ {
            fail "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!"
          }
        }
        'squeeze': {
          if $version !~ /^(8.4|9.0|9.1)$/ {
            fail "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!"
          }
        }
        'wheezy': {
          if $version != '9.1' {
            fail "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!"
          }
        }
        'lucid': {
          if $version != '8.4' {
            fail "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!"
          }
        }
        /^(precise|quantal)$/: {
          if $postgresql_version != '9.1' {
            fail "version ${version} is not supported for ${::operatingsystem} ${::lsbdistcodename}!"
          }
        }
        default: { fail "${::operatingsystem} ${::lsbdistcodename} is not yet supported!" }
      }
    }
    'RedHat' : {
      case $::lsbmajdistrelease {
        '6': {
          if $version != '8.4' {
            fail "version ${version} is not supported for ${::operatingsystem} ${::lsbdistrelease}!"
          }
        }
        default: { fail "${::operatingsystem} ${::lsbdistrelease} is not yet supported!" }
      }
    }
    default: { fail "${::operatingsystem} is not yet supported!" }
  }

  case $::osfamily {
    'RedHat': {
      $data_dir = "${base_dir}/${cluster_name}"
      $conf_dir = $data_dir
      $pg_hba_conf_path = "${conf_dir}/pg_hba.conf"
      $postgresql_conf_path = "${conf_dir}/postgresql.conf"
    }
    'Debian': {
      $data_dir = "${base_dir}/${version}/${cluster_name}"
      $conf_dir = "/etc/postgresql/${version}/${cluster_name}"
      $pg_hba_conf_path = "${conf_dir}/pg_hba.conf"
      $postgresql_conf_path = "${conf_dir}/postgresql.conf"
    }
    default: { fail "${::operatingsystem} is not yet supported!" }
  }

  case $::osfamily {
    'Debian' : { include postgresql::debian }
    'RedHat' : { include postgresql::redhat }
    default: { notice "Unsupported operatingsystem ${::operatingsystem}" }
  }
}
