FROM ubuntu:noble
LABEL MAINTAINER="Madhu Akula" INFO="Kubernetes Goat"

RUN apt-get update && apt-get install -y htop \
    libcap2-bin curl wget && \
    cd /tmp; \
    arch=`uname -m` && \
    if [ $arch = "aarch64" ] || [ $arch = "arm64" ]; then \
        GOTTY="gotty_2.0.0-alpha.3_linux_arm.tar.gz"; \
    else \
        GOTTY="gotty_2.0.0-alpha.3_linux_amd64.tar.gz"; \
    fi; \
    wget https://github.com/yudai/gotty/releases/download/v2.0.0-alpha.3/${GOTTY} \
    && tar -xvzf ${GOTTY}; mv gotty /usr/local/bin/gotty

# ==========================================
# REMEDIATION: Section 5.3 (Missing USER Directive)
# Define non-root user to prevent unrestricted root access
# ==========================================
RUN groupadd -r monitorgroup && useradd -r -g monitorgroup monitoruser
USER monitoruser

EXPOSE 8080

CMD [ "gotty", "-w", "bash" ]
