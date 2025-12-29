#!/bin/bash

# Скрипт удаления Yandex GPT API демона macOS

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║   🗑️  Удаление Yandex GPT API демона                             ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Проверка macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Этот скрипт работает только на macOS"
    exit 1
fi

# Запрос подтверждения
echo "⚠️  ВНИМАНИЕ: Будут удалены следующие файлы:"
echo ""
echo "  • ~/Library/LaunchAgents/com.yandex-gpt.api.plist"
echo "  • /usr/local/bin/yandex-gpt-api"
echo "  • /usr/local/etc/yandex-gpt/ (включая .env и system_prompt.txt)"
echo "  • /usr/local/var/log/yandex-gpt-api*.log"
echo ""
read -p "Вы уверены? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Отменено"
    exit 0
fi

echo ""

# Остановка службы
echo "🛑 Остановка службы..."
if launchctl list | grep -q "com.yandex-gpt.api"; then
    launchctl stop com.yandex-gpt.api 2>/dev/null || true
    echo "✅ Служба остановлена"
else
    echo "ℹ️  Служба не запущена"
fi

# Выгрузка LaunchAgent
echo "📤 Выгрузка LaunchAgent..."
if [ -f ~/Library/LaunchAgents/com.yandex-gpt.api.plist ]; then
    launchctl unload ~/Library/LaunchAgents/com.yandex-gpt.api.plist 2>/dev/null || true
    echo "✅ LaunchAgent выгружен"
else
    echo "ℹ️  LaunchAgent не найден"
fi

sleep 2

# Удаление файлов
echo ""
echo "🗑️  Удаление файлов..."

# LaunchAgent
if [ -f ~/Library/LaunchAgents/com.yandex-gpt.api.plist ]; then
    rm ~/Library/LaunchAgents/com.yandex-gpt.api.plist
    echo "✅ LaunchAgent удален"
fi

# Бинарный файл
if [ -f /usr/local/bin/yandex-gpt-api ]; then
    sudo rm /usr/local/bin/yandex-gpt-api
    echo "✅ Бинарный файл удален"
fi

# Конфигурация
if [ -d /usr/local/etc/yandex-gpt ]; then
    echo ""
    read -p "Удалить конфигурацию (/usr/local/etc/yandex-gpt)? (y/n): " DEL_CONFIG
    if [ "$DEL_CONFIG" = "y" ]; then
        sudo rm -rf /usr/local/etc/yandex-gpt
        echo "✅ Конфигурация удалена"
    else
        echo "ℹ️  Конфигурация сохранена"
    fi
fi

# Логи
if ls /usr/local/var/log/yandex-gpt-api*.log 1> /dev/null 2>&1; then
    echo ""
    read -p "Удалить логи (/usr/local/var/log/yandex-gpt-api*.log)? (y/n): " DEL_LOGS
    if [ "$DEL_LOGS" = "y" ]; then
        sudo rm /usr/local/var/log/yandex-gpt-api*.log
        echo "✅ Логи удалены"
    else
        echo "ℹ️  Логи сохранены"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "✅ УДАЛЕНИЕ ЗАВЕРШЕНО"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Проверка остатков
REMAINING=0

if launchctl list | grep -q "com.yandex-gpt.api"; then
    echo "⚠️  Служба все еще в списке launchctl"
    REMAINING=1
fi

if [ -f ~/Library/LaunchAgents/com.yandex-gpt.api.plist ]; then
    echo "⚠️  LaunchAgent не удален: ~/Library/LaunchAgents/com.yandex-gpt.api.plist"
    REMAINING=1
fi

if [ -f /usr/local/bin/yandex-gpt-api ]; then
    echo "⚠️  Бинарный файл не удален: /usr/local/bin/yandex-gpt-api"
    REMAINING=1
fi

if [ $REMAINING -eq 0 ]; then
    echo "✨ Демон полностью удален из системы"
else
    echo ""
    echo "Для полного удаления выполните вручную:"
    echo "  launchctl remove com.yandex-gpt.api"
    echo "  rm ~/Library/LaunchAgents/com.yandex-gpt.api.plist"
    echo "  sudo rm /usr/local/bin/yandex-gpt-api"
fi

echo ""

