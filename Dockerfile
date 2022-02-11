FROM ubuntu/postgres:12-20.04_beta

RUN echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend \
    && apt-get update -y \
    # Install Patroni and its dependencies.
    && apt-cache depends patroni | sed -n -e 's/.* Depends: \(python3-.\+\)$/\1/p' \
            | grep -Ev '^python3-(sphinx|etcd|consul|kazoo|kubernetes)' \
            | xargs apt-get install -y git python3-pip python3-wheel \
    && pip3 install setuptools \
    && pip3 install 'git+https://github.com/zalando/patroni.git@v2.1.2#egg=patroni[kubernetes]' \
    # Clean up.
    && apt-get remove -y git python3-pip python3-wheel \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /root/.cache

# Expose PostgreSQL and Patroni REST API ports.
EXPOSE 5432 8008