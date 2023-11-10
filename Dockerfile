#
# Stack
#
ARG ELIXIR_VERSION=1.14.0
ARG OTP_VERSION=24.3.4
ARG DEBIAN_VERSION=bullseye-20210902-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

#
# Builder
#
FROM ${BUILDER_IMAGE} AS builder

# Confgiuration
ARG HTTP_PORT=4444
ENV HTTP_PORT=${HTTP_PORT}

# Installing hex + rebar
WORKDIR /tmp
RUN mix local.rebar --force \
  && mix local.hex --force
COPY . .

# Compile, release
RUN mix do deps.get, clean, compile \
  && mkdir -p /tmp/built \ 
  && mix release --path /tmp/built 

#
# Runner
#
FROM ${RUNNER_IMAGE}

# Installing inotify-tools, locales
RUN apt-get update -y \ 
  && apt-get install -y inotify-tools \
  && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Workdir in the subuser dir
WORKDIR /home/app

# Subuser
RUN chown nobody .

# Move the built project
COPY --from=builder --chown=nobody:root /tmp/built .

# Enter subuser
USER nobody

# Here we go
ENTRYPOINT [ "/home/app/bin/oh_my_adolf" ]
CMD "start"