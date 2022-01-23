FROM photon

RUN tdnf install shadow -y && \
    tdnf upgrade -y && \
    groupadd -g 1001 app && \
    useradd -l -r -d /app -u 1001 -g 1001 -s /sbin/nologin app && \
    mkdir -p /app /app/conf /app/public && \
    chown -R app:0 /app

COPY bin/health-checker-linux /app/health-checker
RUN chmod +x /app/health-checker

COPY conf/test.yml /app/conf/
COPY public/ /app/public/

USER app
WORKDIR /app
ENV HOME=/app
ENV KEMAL_ENV=production

EXPOSE 3000
ENTRYPOINT ["./health-checker", "-c", "conf/test.yml"]
