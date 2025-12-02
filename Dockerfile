FROM analogic/poste.io:latest

# Konfiguracja dla Hugging Face Spaces
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

# Timezone
ENV TZ=Europe/Warsaw

# Optymalizacja zasobów - wyłączenie ClamAV (anti-virus)
ENV DISABLE_CLAMAV=TRUE

# Port dla Hugging Face Spaces (webmail/admin interface)
ENV HTTP_PORT=7860 \
    HTTPS=OFF

# Utworzenie katalogu danych (wymagane przez Poste.io)
RUN mkdir -p /data && \
    chmod 777 /data

# Eksponowanie portów
# 7860 - HTTP webmail + admin panel (główny dla HF Spaces)
# 25   - SMTP (odbieranie poczty)
# 587  - SMTP Submission (wysyłanie poczty)
# 143  - IMAP (dostęp do skrzynek)
# 993  - IMAPS (bezpieczny IMAP)
EXPOSE 7860 25 587 143 993

# Healthcheck - sprawdzenie czy serwer działa
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:7860/ || exit 1

# Użycie natywnego init system Poste.io (s6-overlay)
# HF Spaces ma czysty kontener przy każdym starcie - nie potrzeba cleanup
CMD ["/init"]
