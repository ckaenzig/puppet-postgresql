# Definition: postgresql::conf
#
# Add/remove parameters from postgresql.conf file.
# NB: puppet reloads or restarts postgresql each time a change is made
# to postgresql.conf using this definition.
#
# Parameters:
#   ['ensure'] - Whether the setting should be present or absent.
#   ['value']  - The value of the configuration parameter.
#   ['path']   - The path to the configuration file
#
# This is just a wrapper around the pgconf type,
# in case one day we prefer to use augeas or Exec[sed] ;-)
#
# Actions:
# - Creates and manages a postgresql configuration entry.
#
# Requires:
# - `puppetlabs/stdlib`
# - `camptocamp/pgconf`
#
# Sample usage:
#   postgresql::conf { "shared_buffers":
#     value => '128MB',
#   }
#
#   postgresql::conf { "fsync":
#     ensure => absent, # reset to default value
#   }
#
# See also:
#   http://www.postgresql.org/docs/current/static/config-setting.html
#
define postgresql::conf (
  $ensure='present',
  $value=undef,
  $path=false,
) {

  $target = $path ? {
    false   => $postgresql::postgresql_conf_path,
    default => $path,
  }

  case $name {

    /data_directory|hba_file|ident_file|include|listen_addresses|port|max_connections|superuser_reserved_connections|unix_socket_directory|unix_socket_group|unix_socket_permissions|bonjour|bonjour_name|ssl|ssl_ciphers|shared_buffers|max_prepared_transactions|max_files_per_process|shared_preload_libraries|wal_level|wal_buffers|archive_mode|max_wal_senders|hot_standby|logging_collector|silent_mode|track_activity_query_size|autovacuum_max_workers|autovacuum_freeze_max_age|max_locks_per_transaction|max_pred_locks_per_transaction|restart_after_crash/: {
      Pgconf {
        notify => Service["postgresql"],
      }
    }

    default: {
      Pgconf {
        notify => Exec['reload_postgresql'],
      }
    }

  }

  case $ensure {

    /present|absent/: {
      pgconf { $name:
        ensure  => $ensure,
        target  => $target,
        value   => $value,
        require => Package['postgresql'],
      }
    }

    default: {
      fail("Unknown value for ensure '${ensure}'.")
    }
  }

}
