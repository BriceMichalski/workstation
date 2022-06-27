if [ "$2" = "vpn-up" ]; then
  /usr/bin/ifconfig "$1" mtu 1400 up
fi
