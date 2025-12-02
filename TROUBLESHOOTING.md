# 🔧 Troubleshooting Guide

## Problem: "Address already in use" (Port 7860)

### Objawy:
```
bind() to 0.0.0.0:7860 failed (98: Address already in use)
```

### Przyczyna:
Poste.io próbuje uruchomić się wielokrotnie, a stare procesy nadal działają lub lock files pozostały z poprzedniego uruchomienia.

### Rozwiązanie:

**Najnowsza wersja Dockerfile już zawiera fix** - używa wrapper script który czyści lock files przed startem.

Jeśli nadal występuje problem:

1. **Na Hugging Face Spaces:**
   - Kliknij **"Factory reboot"** w Settings
   - Lub **"Rebuild"** przestrzeni

2. **Lokalnie (Docker):**
```bash
# Zatrzymaj kontener
docker stop poste-mailserver

# Usuń kontener
docker rm poste-mailserver

# Wyczyść dane (UWAGA: usuwa wszystkie maile!)
rm -rf ./data

# Uruchom ponownie
docker-compose up -d
```

---

## Problem: "unable to lock_exnb" errors

### Objawy:
```
s6-log: fatal: unable to lock_exnb /data/log/s6/*/lock: Resource temporarily unavailable
```

### Przyczyna:
Lock files z poprzedniego uruchomienia blokują nowe procesy.

### Rozwiązanie:

**Automatycznie naprawione** w najnowszym Dockerfile. Wrapper script usuwa:
- `/data/log/s6/*/lock`
- `/run/*.pid`
- `/var/run/*.pid`
- `/run/login/*`

---

## Problem: "Dovecot is already running"

### Objawy:
```
Fatal: Dovecot is already running? Socket already exists: /run/login/dns-client
```

### Przyczyna:
Stare sockety UNIX z poprzedniego uruchomienia.

### Rozwiązanie:

**Naprawione automatycznie** - wrapper script czyści `/run/login/*`

---

## Problem: "PHP-FPM initialization failed"

### Objawy:
```
[ERROR] Another FPM instance seems to already listen on /var/run/php-fpm-admin.sock
```

### Przyczyna:
Stare PHP-FPM sockety.

### Rozwiązanie:

**Naprawione automatycznie** - wrapper script czyści `/var/run/*.sock` i `/var/run/*.pid`

---

## Problem: Wolne uruchamianie (>5 minut)

### Przyczyna:
Poste.io inicjalizuje:
- Bazy danych (SQLite)
- Certyfikaty SSL
- Konfigurację usług (Dovecot, Haraka, Rspamd)

### To normalne!

Pierwsze uruchomienie trwa **2-5 minut**. Szukaj w logach:
```
Poste.io administration available at:
  - http://10.108.94.195:7860
```

Gdy zobaczysz ten komunikat - gotowe! 🎉

---

## Problem: Strona nie ładuje się

### Sprawdź logi:

**Na HF Spaces:**
1. Wejdź do Space
2. Zakładka **"Logs"**
3. Poszukaj:
   - `[services.d] done.` - usługi uruchomione
   - `Poste.io administration available at:` - adres webmail

**Lokalnie:**
```bash
docker logs -f poste-mailserver
```

### Healthcheck status:
```bash
docker ps
# Sprawdź kolumnę STATUS - powinno być "healthy"
```

---

## Problem: "ClamAV disabled" ale zużycie RAM wysokie

### Przyczyna:
Inne usługi (Rspamd, Redis, Dovecot) też zużywają pamięć.

### Rozwiązanie:

Możesz wyłączyć Rspamd (spam filtering):

**Dockerfile:**
```dockerfile
ENV DISABLE_CLAMAV=TRUE \
    DISABLE_RSPAMD=TRUE
```

**docker-compose.yml:**
```yaml
environment:
  - DISABLE_CLAMAV=TRUE
  - DISABLE_RSPAMD=TRUE
```

**⚠️ Uwaga:** Wyłączenie Rspamd = brak filtrowania spamu!

---

## Problem: Nie mogę wysyłać/odbierać maili

### Na Hugging Face Spaces:

**To normalne!** HF Spaces blokuje porty pocztowe (25, 587, 143, 993).

**Rozwiązanie:**
- Użyj tylko **webmail interface** (port 7860 działa)
- Dla produkcji postaw na **VPS** z własnym IP

### Na VPS:

1. **Sprawdź DNS records:**
```bash
dig MX example.com
dig A mail.example.com
```

2. **Sprawdź otwarte porty:**
```bash
netstat -tuln | grep -E '(25|587|143|993)'
```

3. **Sprawdź firewall:**
```bash
sudo ufw status
# Powinny być otwarte:
# 25/tcp, 587/tcp, 143/tcp, 993/tcp, 443/tcp
```

4. **Test SMTP:**
```bash
telnet mail.example.com 25
# Powinno odpowiedzieć: 220 mail.example.com ESMTP
```

---

## Problem: Zapomniałem hasła admina

### Na Hugging Face Spaces:

**Restart Space** - dane zostaną zresetowane (brak persistent storage).

1. Settings → Factory reboot
2. Poczekaj na restart
3. Utwórz nowe konto admin

### Na VPS:

```bash
# Wejdź do kontenera
docker exec -it poste-mailserver /bin/bash

# Reset hasła admina (jeśli dostępne)
/opt/admin/reset-admin.sh

# LUB usuń bazę admina (wszystkie konta!)
rm /data/admin.db
docker restart poste-mailserver
```

---

## Problem: Restart kontenera = utrata danych

### Przyczyna:

**Hugging Face Spaces nie ma persistent storage!**

Każdy restart = czysty start.

### Rozwiązanie:

**Użyj VPS** dla trwałych danych:

```yaml
volumes:
  - ./data:/data  # Dane lokalne, trwałe
```

---

## Problem: "rsyslogd already running"

### Objawy:
```
rsyslogd: pidfile '/run/rsyslogd.pid' and pid 1679 already exist
```

### Rozwiązanie:

**Naprawione automatycznie** - wrapper script usuwa `/run/*.pid`

---

## Debug Mode - Szczegółowe logi

Jeśli żaden z powyższych nie pomaga:

### Dockerfile z debug:
```dockerfile
FROM analogic/poste.io:latest

ENV TZ=Europe/Warsaw \
    DISABLE_CLAMAV=TRUE \
    HTTP_PORT=7860 \
    HTTPS=OFF \
    DEBUG=1

RUN mkdir -p /data && chmod 777 /data

# Wrapper z verbose logging
RUN echo '#!/bin/bash\n\
set -ex  # Verbose mode\n\
echo "[DEBUG] Cleaning lock files..."\n\
find /data/log/s6 -name "lock" -delete -print 2>/dev/null || true\n\
find /run -name "*.pid" -delete -print 2>/dev/null || true\n\
find /var/run -name "*.pid" -delete -print 2>/dev/null || true\n\
rm -rfv /run/login/* 2>/dev/null || true\n\
echo "[DEBUG] Starting /init..."\n\
exec /init' > /startup-wrapper.sh && \
    chmod +x /startup-wrapper.sh

EXPOSE 7860
CMD ["/startup-wrapper.sh"]  
```

---

## Dalsze wsparcie

Jeśli problem nadal występuje:

1. **Otwórz Issue** na GitHub:
   - [github.com/arturwyroslak/posteio-mailserver/issues](https://github.com/arturwyroslak/posteio-mailserver/issues)

2. **Dołącz:**
   - Pełne logi z HF Spaces lub `docker logs`
   - Twój Dockerfile
   - Opis co próbowałeś

3. **Oficjalna dokumentacja Poste.io:**
   - [poste.io/doc](https://poste.io/doc/)

---

**Made with ❤️ by [arturwyroslak](https://github.com/arturwyroslak)**
