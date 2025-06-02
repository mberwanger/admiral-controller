FROM alpine:3.22

ARG USER=admiral
ARG UID=1000
ARG GID=1000

# Create non-root user and group
RUN addgroup -S -g "$GID" "$USER" && \
    adduser -S -u "$UID" -G "$USER" "$USER"

# Minimal upgrade & install only what's necessary
RUN apk --no-cache add --upgrade ca-certificates && \
    update-ca-certificates

# Set working dir and switch to non-root user
WORKDIR /app
USER "$USER"

# Copy statically-linked binary
COPY --chown=$USER:$USER admiral-controller /app/admiral-controller

ENTRYPOINT ["/app/admiral-controller"]
