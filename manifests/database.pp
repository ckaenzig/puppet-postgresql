# Definition: postgresql
#
# This definition provides a way to manage a postgresql database
# associated to a postgresql cluster.
#
# You must have declared the `postgresql` class before you use
# this definition.
#
# Parameters:
#   ['ensure']      - Whether the database should be present or absent.
#   ['owner']       - The owner of the database.
#                     Defaults to none.
#   ['encoding']    - The encoding used for the database.
#                     Defaults to none.
#   ['template']    - The template used to create the database.
#                     Defaults to template1.
#   ['source']      - The zipped SQL file used to initialize the database.
#                     Defaults to none.
#   ['overwrite']   - Whether to drop the existing database before creating it.
#                     Defaults to false.
#
# Actions:
# - Creates and manages a postgresql database.
#
# Requires:
# - `puppetlabs/stdlib`
#
# Sample Usage:
#   postgresql::database {"foo":
#     ensure => present,
#     owner  => bar,
#   }
#
define postgresql::database(
  $ensure=present,
  $owner=false,
  $encoding=false,
  $template='template1',
  $source=false,
  $overwrite=false,
) {

  $ownerstring = $owner ? {
    false   => '',
    default => "-O $owner"
  }

  $encodingstring = $encoding ? {
    false   => '',
    default => "-E $encoding",
  }

  case $ensure {
    present: {
      exec { "Create $name postgres db":
        command => "createdb $ownerstring $encodingstring $name -T $template",
        user    => 'postgres',
        unless  => "test \$(psql -tA -c \"SELECT count(*)=1 FROM pg_catalog.pg_database where datname='${name}';\") = t",
      }
    }
    absent:  {
      exec { "Remove $name postgres db":
        command => "dropdb $name",
        user    => 'postgres',
        onlyif  => "test \$(psql -tA -c \"SELECT count(*)=1 FROM pg_catalog.pg_database where datname='${name}';\") = t",
      }
    }
    default: {
      fail "Invalid 'ensure' value '$ensure' for postgres::database"
    }
  }

  # Drop database before import
  if $overwrite {
    exec { "Drop database $name before import":
      command => "dropdb ${name}",
      onlyif  => "psql -l | grep '$name  *|'",
      user    => 'postgres',
      before  => Exec["Create $name postgres db"],
    }
  }

  # Import initial dump
  if $source {
    # TODO: handle non-gziped files
    exec { "Import dump into $name postgres db":
      command => "zcat -f ${source} | psql ${name}",
      user    => 'postgres',
      onlyif  => "test $(psql ${name} -c '\\dt' | wc -l) -eq 1",
      require => Exec["Create $name postgres db"],
    }
  }
}
