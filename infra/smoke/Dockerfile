FROM python:3.13-alpine

RUN apk add --no-cache bash curl

WORKDIR /app
COPY server.sh healthcheck.sh /app/
RUN chmod +x /app/server.sh /app/healthcheck.sh

VOLUME ["/data"]

ENV SMOKE_HTTP_PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=5 \
    CMD ["/app/healthcheck.sh"]

ENTRYPOINT ["/app/server.sh"]
