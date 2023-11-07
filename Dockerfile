FROM debian:stable-20210902-slim AS build

RUN apt update ;\
    apt install -y git build-essential bison flex libgps-dev procps

RUN mkdir build && \
    cd build && \
    git clone --depth 1 https://github.com/kn6plv/olsrd.git && \
    cd olsrd && \
    LDFLAGS='-Wl,-rpath,/usr/local/lib' make build_all && \
    LDFLAGS='-Wl,-rpath,/usr/local/lib' make install_all

FROM debian:stable-20210902-slim

EXPOSE 698/udp 8081/tcp 53/udp 53/tcp

COPY root/ /
COPY --from=build /usr/local/sbin/ /usr/local/sbin/
COPY --from=build /etc/olsrd/ /etc/olsrd/
COPY --from=build /usr/local/lib/ /usr/local/lib/
RUN chmod 777 /startup.sh /setup/*.sh /named/*.sh && \
    apt update -y && \
    apt install -y libgps-dev vtun bind9 iptables inotify-tools net-tools dnsutils procps iputils-ping traceroute tcpdump rsyslog curl && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/ && \
    curl -sLo /etc/bind/db.root ftp://ftp.rs.internic.net/domain/db.cache

ENTRYPOINT ["/startup.sh"]
