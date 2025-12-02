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

### 2. Połącz z tym repozytorium

W swoim Space:

```bash
git clone https://huggingface.co/spaces/TWOJA_NAZWA/NAZWA_SPACE
cd NAZWA_SPACE

# Dodaj pliki z tego repo
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/Dockerfile
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/start.sh
wget https://raw.githubusercontent.com/arturwyroslak/posteio-mailserver/main/README.md

# Commit i push
git add .
git commit -m "Add Poste.io mail server"
git push
```

### 3. Poczekaj na build

Hugging Face automatycznie zbuduje i uruchomi kontener. Proces może zająć 5-10 minut.

## 💻 Dostęp do serwera

Po uruchomieniu:

- **Webmail**: `https://TWOJA_NAZWA-NAZWA_SPACE.hf.space`
- **Admin Panel**: `https://TWOJA_NAZWA-NAZWA_SPACE.hf.space/admin`

## ⚙️ Pierwsza konfiguracja

1. **Otwórz webmail interface** w przeglądarce
2. **Kliknij "Create Admin Account"**
3. Wprowadź:
   - Email: `admin@example.com` (dowolna domena do testów)
   - Hasło: silne hasło
4. **Zaloguj się do panelu admina**
5. Skonfiguruj:
   - Domenę (Virtual Domains)
   - Skrzynki pocztowe (Mailboxes)
   - Użytkowników (Users)

## 📦 Porty i usługi

| Port | Usługa | Status |
|------|---------|--------|
| 7860 | HTTP (Webmail + Admin) | ✅ Aktywny |
| 25 | SMTP | ⚠️ Ograniczony na HF |
| 587 | SMTP Submission | ⚠️ Ograniczony na HF |
| 143 | IMAP | ⚠️ Ograniczony na HF |
| 993 | IMAPS | ⚠️ Ograniczony na HF |

**Uwaga**: Hugging Face Spaces ma ograniczenia w portach pocztowych. Ten setup działa najlepiej jako:
- **Webmail demo/test**
- **Panel administracyjny**
- **Prototyp interfejsu**

Dla pełnego serwera pocztowego wymagany jest VPS z własnymi rekordami DNS.

## 🔧 Konfiguracja w Dockerfile

```dockerfile
# Wyłączenie resource-intensive funkcji
ENV DISABLE_CLAMAV=TRUE

# Port dla HF Spaces
ENV HTTP_PORT=7860
ENV HTTPS=OFF

# Timezone
ENV TZ=Europe/Warsaw
```

## 📊 Monitorowanie

Logi w czasie rzeczywistym:

```bash
# W HF Spaces logs tab
docker logs -f mailserver
```

## ⚠️ Ograniczenia na Hugging Face Spaces

1. **Brak stałego IP** - DNS MX records nie zadziałają
2. **Porty pocztowe ograniczone** - SMTP/IMAP mogą być zablokowane
3. **Brak trwałego storage** - restart = utrata danych
4. **CPU/RAM limity** - mogą wpłynąć na wydajność

**Rozwiązanie**: Użyj tego jako **demo/prototyp**, a produkcję postaw na VPS.

## 🏗️ Dla produkcji - VPS Setup

### docker-compose.yml dla VPS

```yaml
version: '3.8'

services:
  mailserver:
    image: analogic/poste.io:latest
    container_name: poste-mailserver
    hostname: mail.example.com
    restart: unless-stopped
    network_mode: host  # Zalecane przez Poste.io
    environment:
      - TZ=Europe/Warsaw
      - HTTPS=ON
    volumes:
      - ./data:/data
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

### DNS Records (dla VPS)

```
# A Record
mail.example.com.    A    YOUR_SERVER_IP

# MX Record  
example.com.         MX   10 mail.example.com.

# SPF Record
example.com.         TXT  "v=spf1 mx ip4:YOUR_SERVER_IP -all"

# DMARC Record
_dmarc.example.com.  TXT  "v=DMARC1; p=quarantine; rua=mailto:admin@example.com"
```

## 📚 Dokumentacja

- [Oficjalna dokumentacja Poste.io](https://poste.io/doc/)
- [Docker Hub - analogic/poste.io](https://hub.docker.com/r/analogic/poste.io)
- [GitHub Repository](https://github.com/arturwyroslak/posteio-mailserver)

## 🐛 Znane problemy

1. **Restart powoduje utratę danych** - HF Spaces nie ma persistent storage
2. **ClamAV wyłączony** - aby zmniejszyć zużycie RAM
3. **SMTP blokada** - wiele platform blokuje port 25

## 🤝 Contributing

Pull requesty mile widziane!

## 📜 Licencja

MIT License

## 👏 Credits

- [Poste.io](https://poste.io) - Fantastyczny all-in-one mail server
- [Hugging Face](https://huggingface.co) - Hosting platform

---

**Made with ❤️ by [arturwyroslak](https://github.com/arturwyroslak)**
