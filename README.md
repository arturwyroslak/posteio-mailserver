---
title: Poste.io Mail Server
emoji: 📧
colorFrom: blue
colorTo: cyan
sdk: docker
app_port: 7860
pinned: false
license: mit
---

# 📧 Poste.io Mail Server

Kompletny serwer pocztowy z webmail interface działający na Hugging Face Spaces.

## ✨ Funkcje

- **📨 Pełny serwer pocztowy**: SMTP, IMAP, POP3
- **🌐 Webmail**: Wbudowany klient webowy do czytania poczty
- **🔧 Panel administracyjny**: Zarządzanie domenami, użytkownikami, skrzynkami
- **🔒 Bezpieczeństwo**: Anti-spam, filtrowanie, szyfrowanie
- **📊 Lekki**: Optymalizowany pod HF Spaces (ClamAV wyłączony)

## 🚀 Szybki Start na Hugging Face Spaces

### 1. Utwórz nowy Space

1. Wejdź na [huggingface.co/spaces](https://huggingface.co/spaces)
2. Kliknij **"Create new Space"**
3. Wybierz:
   - **Space SDK**: Docker
   - **Visibility**: Public lub Private
   - **Space hardware**: CPU basic (wystarczy)

### 2. Dodaj Dockerfile

**Metoda A - Bezpośrednio w HF UI:**

1. W swoim Space kliknij **"Files" → "Add file"**
2. Nazwa: `Dockerfile`
3. Skopiuj zawartość z [tego linka](https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/Dockerfile)
4. Commit

**Metoda B - Przez git:**

```bash
git clone https://huggingface.co/spaces/TWOJA_NAZWA/NAZWA_SPACE
cd NAZWA_SPACE

# Pobierz Dockerfile
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/Dockerfile

# Commit i push
git add Dockerfile
git commit -m "Add Poste.io mail server"
git push
```

### 3. Poczekaj na build

Hugging Face automatycznie zbuduje i uruchomi kontener. Proces może zająć **3-5 minut**.

## 💻 Dostęp do serwera

Po uruchomieniu:

- **Webmail**: `https://TWOJA_NAZWA-NAZWA_SPACE.hf.space`
- **Admin Panel**: `https://TWOJA_NAZWA-NAZWA_SPACE.hf.space/admin`

## ⚙️ Pierwsza konfiguracja

1. **Otwórz webmail interface** w przeglądarce
2. Przy pierwszym uruchomieniu zobaczysz: **"Set up admin account"**
3. Wprowadź:
   - Email: `admin@example.com` (możesz użyć dowolnej domeny do testów)
   - Hasło: silne hasło (min. 8 znaków)
4. **Zaloguj się do panelu admina**
5. Skonfiguruj:
   - **Virtual Domains** - dodaj domenę (np. `example.com`)
   - **Mailboxes** - utwórz skrzynki pocztowe
   - **Users** - dodaj użytkowników

## 📦 Porty i usługi

| Port | Usługa | Status | Opis |
|------|---------|--------|------|
| 7860 | HTTP (Webmail + Admin) | ✅ Działa | Główny interfejs |
| 25 | SMTP | ⚠️ Ograniczony | Odbieranie poczty |
| 587 | SMTP Submission | ⚠️ Ograniczony | Wysyłanie poczty |
| 143 | IMAP | ⚠️ Ograniczony | Dostęp do skrzynek |
| 993 | IMAPS | ⚠️ Ograniczony | Bezpieczny IMAP |

**Uwaga**: Hugging Face Spaces ma ograniczenia w portach pocztowych (25, 587, 143, 993). Ten setup działa najlepiej jako:
- ✅ **Webmail demo/test** - pełna funkcjonalność interfejsu
- ✅ **Panel administracyjny** - pełne zarządzanie
- ✅ **Prototyp UI/UX** - testowanie wyglądu i funkcji
- ❌ **Produkcyjny mail server** - wymaga VPS

Dla pełnego serwera pocztowego wymagany jest VPS z własnymi rekordami DNS.

## 📁 Którego Dockerfile użyć?

### `Dockerfile` - Dla Hugging Face Spaces

```dockerfile
FROM analogic/poste.io:latest
ENV TZ=Europe/Warsaw
ENV DISABLE_CLAMAV=TRUE
ENV HTTP_PORT=7860 HTTPS=OFF
RUN mkdir -p /data && chmod 777 /data
EXPOSE 7860 25 587 143 993
CMD ["/init"]  # Prosty start - HF ma czysty kontener
```

**Użyj dla:**
- ✅ Hugging Face Spaces
- ✅ Demo/test bez persistent storage
- ✅ Aplikacje gdzie każdy restart = czysty kontener

### `Dockerfile.cleanup` - Dla VPS/Local

```dockerfile
FROM analogic/poste.io:latest
ENV TZ=Europe/Warsaw DISABLE_CLAMAV=TRUE
ENV HTTP_PORT=80 HTTPS=ON
COPY startup-wrapper.sh /startup-wrapper.sh
CMD ["/startup-wrapper.sh"]  # Cleanup przed startem
```

**Użyj dla:**
- ✅ VPS z persistent volume `/data`
- ✅ Docker lokalnie z volume mount
- ✅ Produkcja gdzie dane przetrwają restart
- ✅ Problemy z lock files po restartach

## 🔧 Konfiguracja w Dockerfile

Minimalistyczny Dockerfile dla HF Spaces:

```dockerfile
FROM analogic/poste.io:latest

# Timezone
ENV TZ=Europe/Warsaw

# Optymalizacja zasobów
ENV DISABLE_CLAMAV=TRUE

# Port dla HF Spaces
ENV HTTP_PORT=7860 \
    HTTPS=OFF

# Katalog danych
RUN mkdir -p /data && chmod 777 /data

EXPOSE 7860 25 587 143 993

# Bezpośredni start - brak cleanup potrzebny
CMD ["/init"]
```

**Kluczowe zmienne środowiskowe:**
- `HTTP_PORT=7860` - port webmail/admin (wymagany przez HF Spaces)
- `DISABLE_CLAMAV=TRUE` - oszczędza ~500MB RAM
- `HTTPS=OFF` - HF Spaces dodaje HTTPS automatycznie
- `TZ=Europe/Warsaw` - strefa czasowa

## 📊 Monitorowanie

Logi w czasie rzeczywistym w HF Spaces:

1. Wejdź do swojego Space
2. Kliknij zakładkę **"Logs"**
3. Szukaj:
   - `Poste.io administration available at:` - adres webmail
   - `[services.d] done.` - serwis uruchomiony

## ⚠️ Ograniczenia na Hugging Face Spaces

| Ograniczenie | Wpływ | Rozwiązanie |
|-------------|--------|-------------|
| **Brak stałego IP** | DNS MX nie działa | Użyj VPS dla produkcji |
| **Porty pocztowe** | SMTP/IMAP mogą być zablokowane | Tylko webmail działa pełnią |
| **Brak persistent storage** | Restart = utrata danych | Użyj jako demo/test |
| **CPU/RAM limity** | Wolniejsze działanie | DISABLE_CLAMAV=TRUE pomaga |

**Rozwiązanie**: Użyj tego jako **demo/prototyp**, a produkcję postaw na VPS.

## 🏗️ Dla produkcji - VPS Setup

### Quick Start na VPS

```bash
# Zainstaluj Docker
curl -fsSL https://get.docker.com | sh

# Pobierz pliki
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/Dockerfile.cleanup
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/startup-wrapper.sh
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/docker-compose.yml

# Edytuj hostname
nano docker-compose.yml  # Zmień mail.example.com na swoją domenę

# Uruchom
docker-compose up -d

# Sprawdź logi
docker-compose logs -f
```

### docker-compose.yml dla VPS

```yaml
version: '3.8'

services:
  mailserver:
    build:
      context: .
      dockerfile: Dockerfile.cleanup  # Użyj wersji z cleanup
    container_name: poste-mailserver
    hostname: mail.example.com  # ZMIEŃ!
    restart: unless-stopped
    environment:
      - TZ=Europe/Warsaw
      - HTTPS=ON  # Let's Encrypt auto-cert
    volumes:
      - ./data:/data  # Trwałe dane
    ports:
      - "25:25"      # SMTP
      - "80:80"      # HTTP
      - "110:110"    # POP3
      - "143:143"    # IMAP
      - "443:443"    # HTTPS
      - "465:465"    # SMTPS
      - "587:587"    # Submission
      - "993:993"    # IMAPS
      - "995:995"    # POP3S
      - "4190:4190"  # ManageSieve
```

### DNS Records (wymagane dla VPS)

```dns
# A Record
mail.example.com.    A    YOUR_SERVER_IP

# MX Record (najważniejszy!)
example.com.         MX   10 mail.example.com.

# SPF Record (anti-spam)
example.com.         TXT  "v=spf1 mx ip4:YOUR_SERVER_IP -all"

# DMARC Record (bezpieczeństwo)
_dmarc.example.com.  TXT  "v=DMARC1; p=quarantine; rua=mailto:admin@example.com"

# DKIM - wygeneruj w panelu Poste.io po instalacji
```

## 📚 Dokumentacja

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Pełny guide: HF Spaces, Local, VPS
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Rozwiązywanie problemów
- [Oficjalna dokumentacja Poste.io](https://poste.io/doc/)
- [Docker Hub - analogic/poste.io](https://hub.docker.com/r/analogic/poste.io)
- [GitHub Repository](https://github.com/arturwyroslak/posteio-mailserver)

## 🐛 Znane problemy i rozwiązania

### Problem: "Address already in use" (Port 7860)

**Na HF Spaces:**
- ✅ Użyj prostego `Dockerfile` (bez startup-wrapper.sh)
- ✅ Factory reboot Space w Settings

**Na VPS/Local:**
- ✅ Użyj `Dockerfile.cleanup` z startup-wrapper.sh
- ✅ Lub ręcznie: `docker stop poste && docker rm poste && docker-compose up -d`

### Problem: Restart powoduje utratę danych

**Przyczyna:** HF Spaces nie ma persistent storage

**Rozwiązanie:** Użyj VPS z volume mount: `./data:/data`

### Problem: Za wolne

**Rozwiązanie:**
```dockerfile
ENV DISABLE_CLAMAV=TRUE   # Już ustawione
ENV DISABLE_RSPAMD=TRUE   # Dodaj to jeśli nadal wolne
```

Więcej rozwiązań: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 🔥 Szybkie porady

**Pierwsze uruchomienie trwa długo?**
- To normalne! Poste.io inicjalizuje bazy danych, co zabiera 2-3 minuty
- Poczekaj aż zobaczysz: `Poste.io administration available at:`

**Zapomniałeś hasła admina?**
- **HF Spaces:** Restart Space (dane zostaną zresetowane)
- **VPS:** `docker exec -it poste-mailserver rm /data/admin.db && docker restart poste-mailserver`

**Chcesz przetestować lokalnie?**
```bash
docker run -d \
  -p 7860:80 \
  -e DISABLE_CLAMAV=TRUE \
  -e HTTP_PORT=80 \
  -v ./data:/data \
  --name poste-test \
  analogic/poste.io
```

## 🤝 Contributing

Pull requesty mile widziane! Jeśli znajdziesz bug lub masz pomysł na ulepszenie:

1. Fork this repo
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📜 Licencja

MIT License

## 👏 Credits

- [Poste.io](https://poste.io) - Fantastyczny all-in-one mail server od analogic
- [Hugging Face](https://huggingface.co) - Niesamowita platforma do hostingu
- [s6-overlay](https://github.com/just-containers/s6-overlay) - Init system używany przez Poste.io

---

**Made with ❤️ for Polish developers by [arturwyroslak](https://github.com/arturwyroslak)**

**Star ⭐ this repo if you find it useful!**
