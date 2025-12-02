# 🚀 Deployment Guide

## Wybierz metodę deploymentu

Masz **3 opcje** uruchomienia Poste.io:

### 🌐 Opcja 1: Hugging Face Spaces (Najszybsza - Demo/Test)

Najlepsze dla: Demo, prototypy, testowanie interfejsu

**Metoda A - Pojedynczy plik (Ultra-szybka)**

Skopiuj tylko Dockerfile:

```dockerfile
FROM analogic/poste.io:latest

ENV TZ=Europe/Warsaw \
    DISABLE_CLAMAV=TRUE \
    HTTP_PORT=7860 \
    HTTPS=OFF

RUN mkdir -p /data && chmod 777 /data

# Inline cleanup wrapper
RUN echo '#!/bin/bash\n\
set -e\n\
echo "[Cleanup] Removing stale files..."\n\
rm -rf /data/log/s6/*/lock /run/*.pid /var/run/*.pid /run/login/* 2>/dev/null || true\n\
echo "[Startup] Starting Poste.io..."\n\
exec /init' > /startup-wrapper.sh && chmod +x /startup-wrapper.sh

EXPOSE 7860
CMD ["/startup-wrapper.sh"]
```

**Metoda B - Z osobnym skryptem (Zalecana)**

1. Pobierz oba pliki:
```bash
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/Dockerfile
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/startup-wrapper.sh
```

2. Commit do HF Space:
```bash
git add Dockerfile startup-wrapper.sh
git commit -m "Add Poste.io mail server"
git push
```

**Czego się spodziewać:**
- Build: 5-10 minut
- Dostęp: `https://TWOJA_NAZWA-SPACE.hf.space`
- Restart = utrata danych (brak persistent storage)

---

### 💻 Opcja 2: Lokalnie (Docker)

Najlepsze dla: Development, testy lokalne

**Quick Start:**

```bash
# Pobierz repozytorium
git clone https://github.com/arturwyroslak/posteio-mailserver.git
cd posteio-mailserver

# Zbuduj obraz
docker build -t poste-mailserver .

# Uruchom
docker run -d \
  -p 7860:7860 \
  -p 25:25 \
  -p 587:587 \
  -p 143:143 \
  -p 993:993 \
  -v $(pwd)/data:/data \
  --name poste-mailserver \
  poste-mailserver

# Sprawdź logi
docker logs -f poste-mailserver
```

**Dostęp:**
- Webmail: http://localhost:7860
- Admin: http://localhost:7860/admin

**Trwałe dane:**
- Volume `./data` przechowuje wszystkie maile i konfigurację

---

### 🖥️ Opcja 3: VPS/Produkcja (Docker Compose)

Najlepsze dla: Produkcyjny mail server, pełna funkcjonalność

**Wymagania:**
- VPS z publicznym IP
- Domena z dostepem do DNS
- Port 25 otwarty (niektóre providery blokują!)

**Quick Setup:**

```bash
# 1. Zainstaluj Docker
curl -fsSL https://get.docker.com | sh

# 2. Pobierz docker-compose.yml
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/docker-compose.yml

# 3. Edytuj hostname
nano docker-compose.yml
# Zmień: hostname: mail.example.com
# Na: hostname: mail.TWOJA_DOMENA.com

# 4. Uruchom
docker-compose up -d

# 5. Sprawdź status
docker-compose ps
docker-compose logs -f
```

**Konfiguracja DNS (KRYTYCZNE!):**

```dns
# A Record
mail.example.com.    IN  A     YOUR_SERVER_IP

# MX Record (najważniejszy!)
example.com.         IN  MX    10 mail.example.com.

# SPF (anti-spam)
example.com.         IN  TXT   "v=spf1 mx ip4:YOUR_SERVER_IP -all"

# DMARC (bezpieczeństwo)
_dmarc.example.com.  IN  TXT   "v=DMARC1; p=quarantine; rua=mailto:admin@example.com"

# PTR/Reverse DNS (skonfiguruj u providera VPS!)
YOUR_SERVER_IP       IN  PTR   mail.example.com.
```

**Test DNS:**
```bash
# Sprawdź MX record
dig MX example.com +short
# Powinno zwracać: 10 mail.example.com.

# Sprawdź A record
dig A mail.example.com +short
# Powinno zwracać: YOUR_SERVER_IP

# Test SMTP
telnet mail.example.com 25
# Powinno odpowiedzieć: 220 mail.example.com ESMTP
```

**Firewall:**
```bash
# Ubuntu/Debian
sudo ufw allow 25/tcp    # SMTP
sudo ufw allow 587/tcp   # Submission
sudo ufw allow 143/tcp   # IMAP
sudo ufw allow 993/tcp   # IMAPS
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

**SSL/TLS (Let's Encrypt):**

Poste.io automatycznie wygeneruje certyfikaty po:
1. Prawidłowej konfiguracji DNS (A record)
2. Ustawieniu `HTTPS=ON` w environment
3. Dostępie do portów 80 i 443

---

## 🛠️ Porównanie opcji

| Cecha | HF Spaces | Lokal | VPS/Produkcja |
|-------|-----------|-------|---------------|
| **Szybkość setupu** | ⭐⭐⭐⭐⭐ 5 min | ⭐⭐⭐⭐ 10 min | ⭐⭐⭐ 30-60 min |
| **Koszt** | ✅ Free | ✅ Free | 💵 $5-20/mies |
| **Webmail** | ✅ Działa | ✅ Działa | ✅ Działa |
| **SMTP/IMAP** | ❌ Zablokowane | ✅ Działa | ✅ Działa |
| **Trwałe dane** | ❌ Restart = utrata | ✅ Volume | ✅ Volume |
| **Własna domena** | ❌ Subdomena HF | ⚠️ localhost | ✅ Pełna kontrola |
| **SSL/TLS** | ✅ Auto (HF) | ⚠️ Self-signed | ✅ Let's Encrypt |
| **Email delivery** | ❌ Nie działa | ⚠️ Lokalnie | ✅ Pełna |
| **DNS records** | ❌ Nie potrzebne | ❌ Nie potrzebne | ✅ Wymagane |
| **Best for** | Demo/Test | Development | Produkcja |

---

## 📝 Pliki wymagane dla każdej opcji

### HF Spaces - Metoda A (Minimal)
```
├── Dockerfile          # Wszystko w jednym
└── README.md           # Opcjonalne (metadane HF)
```

### HF Spaces - Metoda B (Zalecana)
```
├── Dockerfile          # Główny build
├── startup-wrapper.sh  # Cleanup script
└── README.md           # Metadane HF Spaces
```

### Lokal
```
├── Dockerfile
├── startup-wrapper.sh
└── data/               # Volume z danymi
```

### VPS/Produkcja
```
├── docker-compose.yml  # Orchestration
├── data/               # Persistent storage
└── .env                # Zmienne środowiskowe (opcjonalne)
```

---

## ✅ Checklist po deploymencie

### Wszystkie środowiska:
- [ ] Kontener uruchomiony (`docker ps`)
- [ ] Logi bez errorów (`docker logs`)
- [ ] Webmail dostępny (http://localhost:7860 lub HF URL)
- [ ] Możesz utworzyć konto admina
- [ ] Panel admina działa (/admin)

### Dodatkowo dla VPS:
- [ ] DNS records skonfigurowane prawidłowo
- [ ] Firewall otwiera porty pocztowe
- [ ] SSL certyfikaty wygenerowane (Let's Encrypt)
- [ ] Test wysyłania maila (telnet mail.example.com 25)
- [ ] Reverse DNS skonfigurowany u providera
- [ ] SPF, DKIM, DMARC records dodane

---

## 🐛 Troubleshooting

Jeśli coś nie działa, sprawdź:

1. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - kompletny guide
2. **Logi:**
   - HF Spaces: Zakładka "Logs"
   - Docker: `docker logs -f poste-mailserver`
3. **GitHub Issues:** [Zgłoś problem](https://github.com/arturwyroslak/posteio-mailserver/issues)

---

## 📚 Dokumentacja

- [README.md](README.md) - Główna dokumentacja
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Rozwiązywanie problemów
- [Oficjalna doku Poste.io](https://poste.io/doc/)
- [Docker Hub](https://hub.docker.com/r/analogic/poste.io)

---

**Made with ❤️ by [arturwyroslak](https://github.com/arturwyroslak)**
