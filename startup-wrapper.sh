#!/bin/bash

# Startup wrapper dla Poste.io
# Czyści stare lock files i PID files przed startem

set -e

echo "===================================="
echo "Poste.io Startup Wrapper"
echo "===================================="
echo ""

echo "[Cleanup] Removing stale lock files and PIDs..."

# Usuń lock files s6
if [ -d "/data/log/s6" ]; then
    find /data/log/s6 -name "lock" -delete 2>/dev/null || true
    echo "  ✓ Removed s6 lock files"
fi

# Usuń PID files z /run
if [ -d "/run" ]; then
    rm -f /run/*.pid 2>/dev/null || true
    echo "  ✓ Removed /run PID files"
fi

# Usuń PID files z /var/run
if [ -d "/var/run" ]; then
    rm -f /var/run/*.pid 2>/dev/null || true
    rm -f /var/run/*.sock 2>/dev/null || true
    echo "  ✓ Removed /var/run PID/socket files"
fi

# Usuń Dovecot sockets
if [ -d "/run/login" ]; then
    rm -rf /run/login/* 2>/dev/null || true
    echo "  ✓ Removed Dovecot login sockets"
fi

echo ""
echo "[Cleanup] Done!"
echo "[Startup] Starting Poste.io init system..."
echo "===================================="
echo ""

# Uruchom natywny init system Poste.io (s6-overlay)
exec /init
