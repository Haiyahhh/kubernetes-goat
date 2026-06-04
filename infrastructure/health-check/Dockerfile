FROM golang:latest
LABEL MAINTAINER="Madhu Akula" INFO="Kubernetes Goat"

WORKDIR /app

COPY views /app/views
COPY go.mod /app/go.mod
COPY go.sum /app/go.sum
COPY main.go /app/main.go

RUN apt update && apt install curl wget iputils-ping -y

RUN go build -o /app/health-check main.go

EXPOSE 8080

# ==========================================
# REMEDIATION: Section 5.3 (Missing USER Directive)
# Define non-root user to prevent unrestricted root access
# ==========================================

RUN groupadd -g 10001 appgroup && useradd -u 10001 -g 10001 -m -s /bin/bash appuser 
RUN chown -R 10001:10001 /app

USER 10001
CMD ["/app/health-check"]
