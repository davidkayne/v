FROM alpine:latest
ENV PORT=443
ENV ID=472523ae-a4a7-42d9-92a1-e302ddba9757

RUN apk add --no-cache curl unzip bash ca-certificates

COPY configure.sh /configure.sh
RUN chmod +x /configure.sh

CMD ["/configure.sh"]
