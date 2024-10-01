FROM ghcr.io/guymenahem/backstage-platformers:0.0.1

RUN ls -la && \
    echo "some dummy change in image" > change.txt
