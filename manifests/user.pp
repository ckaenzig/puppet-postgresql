# Definition: postgresql::user
#
# This definition provides a way to manage postgresql users
# associated to a postgresql cluster.
#
# You must have declared the `postgresql` class before you use
# this definition.
#
# Parameters:
#   ['ensure']      - Whether the user should be present or absent.
#   ['password']    - Set the password.
#                     Defaults to false.
#   ['superuser']   - Whether the user is a superuser.
#                     Defaults to false.
#   ['createdb']    - Whether the user has rights to create new databases.
#                     Defaults to false.
#   ['createrole']  - Whether to user has rights to create new roles.
#                     Defaults to false.
#   ['hostname']    - The hostname to use to connect to the database.
#                     Defaults to /var/run/postgresql.
#   ['port']        - The port to use to connect to the database.
#                     Defaults to 5432.
#   ['user']        - The user to use to connect to the database.
#                     Defaults to postgres
#
# Actions:
# - Creates and manages a postgresql user
#
# Requires:
# - `puppetlabs/stdlib`
#
# Sample Usage:
#   postgresql::user {'foo':
#     ensure    => present,
#     superuser => true,
#   }
#
define postgresql::user(
  $ensure=present,
  $password=false,
  $superuser=false,
  $createdb=false,
  $createrole=false,
  $hostname='/var/run/postgresql',
  $port='5432',
  $user='postgres',
) {

  $pgpass = $password ? {
    false   => '',
    default => $password,
  }

  # Connection string
  $connection = "-h ${hostname} -p ${port} -U ${user}"

  # Quite aweful 0.25.x backward compatibility hack, used only in the file
  # definition below and will be removed as soon as possible
  if $module_name == '' {
    $module_name = 'postgresql'
  }

  # Script we use to manage postgresql users
  if ! defined( File ['/usr/local/sbin/pp-postgresql-user.sh'] ) {
    file { '/usr/local/sbin/pp-postgresql-user.sh':
      ensure => present,
      source => "puppet:///modules/${module_name}/pp-postgresql-user.sh",
      mode   => '0755',
    }
  }

  case $ensure {
    present: {

      # The createuser command always prompts for the password.
      # User with '-' like www-data must be inside double quotes
      exec { "Create postgres user $name":
        command => $password ? {
          false => "/usr/local/sbin/pp-postgresql-user.sh '${connection}' createusernopwd '${name}'",
          default => "/usr/local/sbin/pp-postgresql-user.sh '${connection}' createuser '${name}' '${password}' ",
        },
        user    => "postgres",
        unless  => "/usr/local/sbin/pp-postgresql-user.sh '${connection}' checkuser '${name}'",
      }

      exec { "Set SUPERUSER attribute for postgres user $name":
        command => inline_template("/usr/local/sbin/pp-postgresql-user.sh '<%= connection %>' setuserrole '<%= name %>' '<%= superuser ? '':'NO' %>SUPERUSER'"),
        user    => "postgres",
        unless  => "/usr/local/sbin/pp-postgresql-user.sh '${connection}' checkuserrole '${name}' '$superuser' rolsuper",
        require => Exec["Create postgres user $name"],
      }

      exec { "Set CREATEDB attribute for postgres user $name":
        command => inline_template("/usr/local/sbin/pp-postgresql-user.sh '<%= connection %>' setuserrole '<%= name %>' '<%= createdb ? '':'NO' %>CREATEDB'"),
        user    => "postgres",
        unless  => "/usr/local/sbin/pp-postgresql-user.sh '${connection}' checkuserrole '${name}' '$createdb' rolcreatedb",
        require => Exec["Create postgres user $name"],
      }

      exec { "Set CREATEROLE attribute for postgres user $name":
        command => inline_template("/usr/local/sbin/pp-postgresql-user.sh '<%= connection %>' setuserrole '<%= name %>' '<%= createrole ? '':'NO' %>CREATEROLE'"),
        user    => "postgres",
        unless  => "/usr/local/sbin/pp-postgresql-user.sh '${connection}' checkuserrole '${name}' '$createrole' rolcreaterole",
        require => Exec["Create postgres user $name"],
      }

      if $password {
        $host = $hostname ? {
          '/var/run/postgresql' => "localhost",
          default               => $hostname,
        }

        # change only if it's not the same password
        exec { "Change password for postgres user $name":
          command => "/usr/local/sbin/pp-postgresql-user.sh '${connection}' setpwd '${name}' '${pgpass}'",
          user    => "postgres",
          unless  => "/usr/local/sbin/pp-postgresql-user.sh '-h ${host} -p ${port} -U ${name}' checkpwd '${host}:${port}:template1:${name}:${pgpass}'",
          require => Exec["Create postgres user $name"],
        }
      }

    }

    absent:  {
      exec { "Delete postgres user $name":
        command => "/usr/local/sbin/pp-postgresql-user.sh '${connection}' dropuser '${name}'",
        user    => "postgres",
        onlyif  => "/usr/local/sbin/pp-postgresql-user.sh '${connection}' checkuser '${name}'",
      }
    }

    default: {
      fail "Invalid 'ensure' value '${ensure}' for postgresql::user"
    }
  }
}
