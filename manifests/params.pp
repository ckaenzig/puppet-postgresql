class postgresql::params {

  $default_version = $::osfamily ? {
    'RedHat' => $::lsbmajdistrelease ? {
      '6'     => '8.4',
      default => 'unsupported',
    },
    'Debian' => $::lsbdistcodename ? {
      'lenny'   => '8.3',
      'squeeze' => '8.4',
      'wheezy'  => '9.1',
      'lucid'   => '8.4',
      'precise' => '9.1',
      'quantal' => '9.1',
      default   => 'unsupported',
    },
    default => 'unsupported',
  }

  if $default_version == 'unsupported' {
    fail "${::operatingsystem} ${lsbdistrelease} is not yet supported"
  }

 
  case $::osfamily {
    'RedHat': {
      $cluster_name = 'data'
      $default_base_dir = '/var/lib/pgsql'
    }
    'Debian': {
      $cluster_name = 'main'
      $default_base_dir = '/var/lib/postgresql'
    }
    default: { fail "${::operatingsystem} is not yet supported!" }
  }

}
