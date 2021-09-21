#! /bin/bash

. /config

ZONEFILE="/etc/bind/${DNS_ZONE}.zone.db"

#
# Create zone file header
#
cat > ${ZONEFILE} <<__EOF__
;
; Zone ${DNS_ZONE}.mesh
;
\$TTL 60
\$ORIGIN ${DNS_ZONE}.mesh.
@	IN	SOA	dns0.${DNS_ZONE}.mesh. root.${DNS_ZONE}.mesh. (
	$(date +%s) ; Serial
	3600 ; Refresh
	300 ; Retry
	604800 ; Expire
	60 ) ; TTL
;
@ IN NS	dns0
dns0 IN A ${PRIMARY_IP}
__EOF__

#
# Create an entry for each valid IP/HOST line
#
cat /var/run/hosts_olsr | while read LINE
do
  words=( $LINE )
  ip=${words[0]}
  host=${words[1]}
  if [[ ${ip} =~ ^10\. && ! ${host} =~ \. ]]; then
    echo "$host	IN A	$ip" >> ${ZONEFILE}
  fi
done

#
# Reload the zone
#
rndc reload ${DNS_ZONE}.mesh
