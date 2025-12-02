FROM analogic/poste.io:latest

# Wymagane dla Hugging Face Spaces
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Konfiguracja timezone
ENV TZ=Europe/Warsaw

# Wyłączenie funkcji wymagających więcej zasobów
ENV DISABLE_CLAMAV=TRUE \
    DISABLE_RSPAMD=FALSE

# Port dla Hugging Face Spaces (webmail/admin interface)
ENV HTTP_PORT=7860 \
    HTTPS=OFF

# Tworzenie użytkownika user (wymagane przez HF)
RUN useradd -m -u 1000 user || true

# Utworzenie katalogu danych
RUN mkdir -p /data && \
    chmod 755 /data

WORKDIR /home/user/app

# Eksponowanie portów
# Port 7860 - główny port dla HF Spaces (webmail + admin)
# Port 25 - SMTP (jeśli HF Spaces to umożliwia)
# Port 587 - Submission port
# Port 143 - IMAP
# Port 993 - IMAPS
EXPOSE 7860 25 587 143 993

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# Skrypt startowy
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
