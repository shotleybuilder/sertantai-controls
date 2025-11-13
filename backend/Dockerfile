# Build stage
FROM elixir:1.16-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    npm

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Copy dependency files
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy application code
COPY . .

# Compile and build release
RUN mix compile
RUN mix release

# Production stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++ \
    postgresql-client

WORKDIR /app

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/sertantai_controls ./

# Create non-root user
RUN addgroup -g 1000 sertantai && \
    adduser -D -u 1000 -G sertantai sertantai && \
    chown -R sertantai:sertantai /app

USER sertantai

EXPOSE 4000

CMD ["/app/bin/sertantai_controls", "start"]
