#
#	PagerMon image
#
FROM slocomptech/bi-node:12

#
#	Arguments
#
ARG BUILD_DATE
ARG NODE_ENV
ARG NPM_ARGS
ARG TAG
ARG VCS_REF
ARG VCS_SRC
ARG VERSION

#
#	Labels
#	@see https://github.com/opencontainers/image-spec/blob/master/annotations.md
#	@see https://semver.org/
#
LABEL org.opencontainers.image.authors="PagerMon Team" \
			org.opencontainers.image.created=${BUILD_DATE} \
			org.opencontainers.image.description="PagerMon server" \
			org.opencontainers.image.documentation="https://github.com/pagermon/pagermon" \
			org.opencontainers.image.revision=${VCS_REF} \
			org.opencontainers.image.source=${VCS_SRC} \
			org.opencontainers.image.title="PagerMon server" \
			org.opencontainers.image.url="https://github.com/pagermon/pagermon"\
			org.opencontainers.image.vendor="PagerMon Team" \
			org.opencontainers.image.version=${VERSION}

#
#	Environment variables.
#	Don't forget to set NODE_ENV
#
ENV APP_NAME=PagerMon \
    APP_VERSION=${VERSION} \
		NODE_ENV=${NODE_ENV:-production}

#
#	Install app in container
#

#
# s6 overlay scripts
#	@see https://github.com/just-containers/s6-overlay
#
COPY root /

COPY . /app/

# Fix file permissions
RUN chown -R $CONTAINER_USER:$CONTAINER_USER /app && \
		chown -R $CONTAINER_USER:$CONTAINER_USER /defaults 

EXPOSE 3000

# Install pagermon
RUN apk add --no-cache sqlite && \
		apk add --no-cache --virtual .build-dependencies \
			autoconf \
			automake \
			build-base \
			cmake \
			gcc \
			g++ \
			make \
			musl-dev \
			python3 && \
		ln -s /usr/bin/python3 /usr/bin/python && \
		cd /app && \
		sudo -u ${CONTAINER_USER} -g ${CONTAINER_USER} npm install ${NPM_ARGS} && \
		rm /usr/bin/python && \
    apk del .build-dependencies && \
    # Link config file to config dir
    sudo -u ${CONTAINER_USER} -g ${CONTAINER_USER} ln -s /config/config.json /app/config/config.json && \
		sudo -u ${CONTAINER_USER} -g ${CONTAINER_USER} ln -s /config/backup.json /app/config/backup.json && \
    sudo -u ${CONTAINER_USER} -g ${CONTAINER_USER} cp /app/config/default.json /defaults/config.json && \
    sed -i 's/"\.\/messages\.db.*"/"\/config\/messages\.db"/' /defaults/config.json
