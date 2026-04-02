FROM debian:bookworm-slim

ARG BUILD_DATE
ARG VCS_REF
ARG RUN_UID=0
ARG RUN_GID=0

COPY ./entrypoint.sh /entrypoint.sh

RUN case "$(dpkg --print-architecture)" in \
 'armhf') PACKAGES='python3-distutils'; printf '%b' '[global]\nextra-index-url=https://www.piwheels.org/simple/\n' > /etc/pip.conf;; \
 *) PACKAGES='gcc libcurl4-openssl-dev libssl-dev python3-dev';; \
 esac && \
 apt-get -q update && \
 DEBIAN_FRONTEND="noninteractive" apt-get -qq --option Dpkg::Options::="--force-confnew" --no-install-recommends install \
 ca-certificates curl python3 fdisk git $PACKAGES && \
 git clone -b dev https://github.com/motioneye-project/motioneye.git /tmp/motioneye && \
 curl -sSfO 'https://bootstrap.pypa.io/get-pip.py' && \
 python3 get-pip.py && \
 python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel && \
 python3 -m pip install --no-cache-dir /tmp/motioneye && \
 motioneye_init --skip-systemd --skip-apt-update && \
 sed -i "s/^\(motion:[^:]*\):[0-9]*:[0-9]*:\(.*\)/\1:${RUN_UID}:${RUN_GID}:\2/" /etc/passwd && \
 sed -i "s/^\(motion:[^:]*\):[0-9]*:\(.*\)/\1:${RUN_GID}:\2/" /etc/group && \
 mv /etc/motioneye/motioneye.conf /etc/motioneye.conf.sample && \
 mkdir /var/log/motioneye /var/lib/motioneye && \
 chown motion:motion /var/log/motioneye /var/lib/motioneye && \
 python3 -m pip uninstall -y pip setuptools wheel && \
 DEBIAN_FRONTEND="noninteractive" apt-get -qq autopurge $PACKAGES && \
 apt-get clean && \
 rm -r /var/lib/apt/lists /var/cache/apt /tmp/motioneye get-pip.py /root/.cache

VOLUME /etc/motioneye
VOLUME /var/lib/motioneye

EXPOSE 8765

ENTRYPOINT ["/entrypoint.sh"]
