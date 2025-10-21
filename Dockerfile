FROM python:3.11-alpine
ENV PORT=443
ENV ID=472523ae-a4a7-42d9-92a1-e302ddba9757

RUN apk add --no-cache curl unzip bash ca-certificates \
    && pip install flask gunicorn

COPY configure.sh /configure.sh
COPY app.py /app.py
RUN chmod +x /configure.sh

EXPOSE 443 8080
CMD ["/configure.sh"]
