FROM ghcr.io/guymenahem/backstage-platformers:0.0.1

RUN ls -la && \
    pwd && \
    rm -rf packages
