FROM python:3.11-alpine
ENV PORT=443
ENV ID=472523ae-a4a7-42d9-92a1-e302ddba9757

RUN apk add --no-cache curl unzip bash ca-certificates python3 py3-pip \
    && pip install flask gunicorn

COPY configure.sh /configure.sh
COPY app.py /app.py
RUN chmod +x /configure.sh

EXPOSE 443 8080
HEALTHCHECK --interval=10s --timeout=3s CMD wget -qO- http://127.0.0.1:8080 || exit 1
CMD ["/configure.sh"]
