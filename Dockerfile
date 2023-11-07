FROM debian:stable AS build

RUN apt update && \
    apt install -y git build-essential bison flex libgps-dev procps

RUN mkdir build && \
    cd build && \
    git clone --depth 1 https://github.com/kn6plv/olsrd.git && \
    cd olsrd && \
    LDFLAGS='-Wl,-rpath,/usr/local/lib' make build_all && \
    LDFLAGS='-Wl,-rpath,/usr/local/lib' make install_all

FROM debian:stable

EXPOSE 698/udp 8081/tcp 53/udp 53/tcp 5525/tcp

COPY root/ /
COPY --from=build /usr/local/ /usr/local/
COPY --from=build /etc/olsrd/ /etc/olsrd/

RUN chmod 777 /startup.sh /setup/*.sh /named/*.sh && \
    apt update -y && \
    apt install -y libgps-dev vtun bind9 iptables inotify-tools net-tools dnsutils procps iputils-ping traceroute tcpdump rsyslog curl lsof && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
    curl -sLo /usr/share/dns/root.hints ftp://ftp.rs.internic.net/domain/db.cache && \
    echo "nameserver 127.0.0.1" > /etc/resolv.conf

ENTRYPOINT ["/startup.sh"]
