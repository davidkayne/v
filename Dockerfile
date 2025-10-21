FROM alpine:latest
ENV PORT=443
ENV ID=472523ae-a4a7-42d9-92a1-e302ddba9757
RUN apk add --no-cache ca-certificates curl unzip bash python3 wget
ADD configure.sh /configure.sh
RUN chmod +x /configure.sh
HEALTHCHECK --interval=10s --timeout=3s CMD wget -qO- http://127.0.0.1:8080 || exit 1
CMD ["/configure.sh"]
