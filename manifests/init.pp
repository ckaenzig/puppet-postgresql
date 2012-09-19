class postgresql {
  case $::operatingsystem {
    /^(Debian|Ubuntu)$/ : { include postgresql::debian }
    default: { notice "Unsupported operatingsystem ${operatingsystem}" }
  }
}
