FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 1000 maxpeeduser && \
    useradd -m -u 1000 -g 1000 -s /bin/bash maxpeeduser

WORKDIR /app

COPY requirements.txt /app/requirements.txt
RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY scripts /app/scripts
RUN chmod +x /app/scripts/*.sh && chown -R maxpeeduser:maxpeeduser /app

USER maxpeeduser
COPY --chown=maxpeeduser:maxpeeduser . /app

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/app/scripts/prod.sh"]
