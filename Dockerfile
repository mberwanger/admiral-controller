# Go build
FROM golang:1.24-bullseye AS gobuild

WORKDIR /app

#COPY go.mod go.sum ./
#RUN go mod download

COPY . .

ARG VERSION
ARG COMMIT
ARG DATE
ARG BUILT_BY=unknown

RUN make build

# Copy binary to final image
FROM gcr.io/distroless/base-debian12

WORKDIR /app

COPY --from=gobuild /app/build/admiral-controller /app

USER nonroot
ENTRYPOINT ["/app/admiral-controller"]
