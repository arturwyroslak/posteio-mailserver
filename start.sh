#!/bin/bash

# Start script dla Poste.io na Hugging Face Spaces

echo "===================================="
echo "Poste.io Mail Server Starting..."
echo "===================================="

# Wyświetlenie informacji o konfiguracji
echo "Configuration:"
echo "  - HTTP Port: ${HTTP_PORT:-7860}"
echo "  - Timezone: ${TZ:-Europe/Warsaw}"
echo "  - ClamAV: ${DISABLE_CLAMAV:-TRUE}"
echo "  - Data directory: /data"
echo ""

# Upewnienie się, że katalog danych istnieje
mkdir -p /data

# Sprawdzenie czy to pierwsze uruchomienie
if [ ! -f "/data/.initialized" ]; then
    echo "First run detected. Initializing..."
    touch /data/.initialized
fi

# Info dla użytkownika
echo ""
echo "===================================="
echo "Poste.io will be available at:"
echo "  - Web Interface: http://localhost:7860"
echo "  - Admin Panel: http://localhost:7860/admin"
echo ""
echo "Default setup:"
echo "  1. Go to the web interface"
echo "  2. Create your first admin account"
echo "  3. Configure your domain and mailboxes"
echo "===================================="
echo ""

# Uruchomienie Poste.io przez s6 supervisor (natywny system Poste.io)
# Poste.io używa s6-overlay jako init system
exec /init
