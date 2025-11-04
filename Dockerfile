FROM debian:stable-slim AS builder

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential \
        subversion \
        automake \
        autoconf \
        libxml2-dev \
        mosquitto-clients \
        git \
        cmake \
        jq \
        iputils-ping \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir openv && cd openv && git clone https://github.com/openv/vcontrold.git vcontrold-code
RUN cd /openv && cmake ./vcontrold-code -DVSIM=ON -DMANPAGES=OFF && \
    make && \
    make install


FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        mosquitto-clients \
        jq \
        iputils-ping \
        logrotate \
        cron \
        bash \
    && rm -rf /var/lib/apt/lists/*

# Copy build artifacts
COPY --from=builder /usr/sbin/vcontrold /usr/local/bin/
COPY --from=builder /usr/bin/vclient /usr/local/bin/

# Copy configurations and scripts
COPY config/ /etc/vcontrold/
COPY startup.sh /
COPY logrotate.conf /etc/logrotate.d/vcontrold

# Setup cron job for logrotate
RUN echo "0 0 * * * /usr/sbin/logrotate /etc/logrotate.d/vcontrold" >> /etc/crontab

# Make startup script executable
RUN chmod +x /startup.sh

EXPOSE 3002/udp
ENTRYPOINT ["/startup.sh"]