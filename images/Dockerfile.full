FROM golang:1.11 AS builder
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y ca-certificates openssh-client postgresql-client git curl make
RUN go get -u github.com/cncf/devstatscode
WORKDIR /go/src/github.com/cncf/devstatscode
ADD devstats.tar .
ADD devstatscode.tar .
ADD devstats-docker-lf.tar .
RUN make -f ./docker/Makefile dockerinstall
RUN make -f ./docker/Makefile links
FROM alpine
RUN apk add git bash postgresql-client xz curl
COPY --from=builder /etc/gha2db /etc/gha2db
COPY --from=builder /go/src/github.com/cncf/devstatscode /go/src/devstats
COPY --from=builder /devstats-minimal/* /usr/bin/
WORKDIR /go/src/devstats
