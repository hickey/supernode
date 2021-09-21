# Generate VTUN client

mkdir /dev/net
mknod -m 666 /dev/net/tun c 10 200

cat > /etc/vtund.conf << __EOF__
options {
  port 5525;
  ifconfig /sbin/ifconfig;
  route /sbin/route;
}
default {
  keepalive yes;
  persist keep;
}
__EOF__

#
# Loop through set of TUNx variables, creating a tunnel for each one.
#
run=":"
tun=0
server=0
while true
do
  vtunr="TUN${tun}"
  vtun=${!vtunr}
  if [ "${vtun}" = "" ]; then
    break
  fi

  name=$(echo ${vtun} | cut -d: -f 1)
  password=$(echo ${vtun} | cut -d: -f 2)
  net=$(echo ${vtun} | cut -d: -f 3)
  target=$(echo ${vtun} | cut -d: -f 4)

  # Generate local and remote IPs from network address
  s=($(echo ${net} | tr "." "\n"))
  localip="${s[0]}.${s[1]}.${s[2]}.$((1 + ${s[3]}))"
  remoteip="${s[0]}.${s[1]}.${s[2]}.$((2 + ${s[3]}))"

  if [ "${target}" = "" ]; then
    # Server config
    if [ "${server}" = "0" ]; then
      server=1
      run="${run};vtund -s"
    fi
    cat >> /etc/vtund.conf << __EOF__
${name}-${s[0]}-${s[1]}-${s[2]}-${s[3]} {
  device tun${tun};
  passwd ${password};
  up {
    ifconfig "%% ${remoteip} netmask 255.255.255.252 pointtopoint ${localip} mtu 1450";
    route "add -net ${net}/30 gw ${localip}";
  }
}
__EOF__
  else
    # Client config
    cat >> /etc/vtund.conf << __EOF__
${name}-${s[0]}-${s[1]}-${s[2]}-${s[3]} {
  device tun${tun};
  passwd ${password};
  up {
    ifconfig "%% ${localip} netmask 255.255.255.252 pointtopoint ${remoteip} mtu 1450";
    route "add -net ${net}/30 gw ${remoteip}";
  }
}
__EOF__
    run="${run};vtund ${name}-${s[0]}-${s[1]}-${s[2]}-${s[3]} ${target}"
  fi
  tun=$((tun + 1))
done

# Start any vtun daemons
bash -c "${run}"
