FROM elixir:alpine
ARG APP_NAME=jobplanner_dinero
ARG PHOENIX_SUBDIR=.
ENV MIX_ENV=prod REPLACE_OS_VARS=true TERM=xterm
WORKDIR /opt/app
RUN apk update \
    && mix local.rebar --force \
    && mix local.hex --force
COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile
COPY . .
RUN mix compile
RUN mix phx.digest
RUN mix release --env=prod --verbose \
    && mv _build/prod/rel/${APP_NAME} /opt/release
FROM alpine:latest
RUN apk update && apk --no-cache --update add bash openssl-dev
ENV PORT=4000 MIX_ENV=prod REPLACE_OS_VARS=true
WORKDIR /opt/app
EXPOSE ${PORT}
COPY --from=0 /opt/release .
CMD ["/opt/app/bin/jobplanner_dinero", "foreground"]