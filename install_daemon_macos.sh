#!/bin/bash

# Скрипт установки Yandex GPT API как демона macOS

set -e

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║   🚀 Установка Yandex GPT API как демона macOS                   ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Проверка macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Этот скрипт работает только на macOS"
    exit 1
fi

# Проверка наличия бинарного файла
if [ ! -f "bin/yandex-gpt-api" ]; then
    echo "📦 Бинарный файл не найден. Собираем..."
    go build -o bin/yandex-gpt-api cmd/api/main.go
    echo "✅ Сборка завершена"
else
    echo "✅ Бинарный файл найден"
fi

# Проверка наличия .env
if [ ! -f ".env" ]; then
    echo "❌ Файл .env не найден!"
    echo "Создайте .env файл с необходимыми параметрами"
    echo "См. .env.example для примера"
    exit 1
fi

echo "✅ Конфигурация .env найдена"
echo ""

# Запрос подтверждения
echo "Скрипт установит следующие файлы:"
echo "  • /usr/local/bin/yandex-gpt-api"
echo "  • /usr/local/etc/yandex-gpt/.env"
echo "  • /usr/local/etc/yandex-gpt/system_prompt.txt"
echo "  • ~/Library/LaunchAgents/com.yandex-gpt.api.plist"
echo ""
read -p "Продолжить? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Отменено"
    exit 0
fi

echo ""
echo "📁 Создание директорий..."

# Создание директорий
sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/local/etc/yandex-gpt
sudo mkdir -p /usr/local/var/log

echo "✅ Директории созданы"
echo ""

# Копирование бинарного файла
echo "📦 Копирование бинарного файла..."
sudo cp bin/yandex-gpt-api /usr/local/bin/
sudo chmod +x /usr/local/bin/yandex-gpt-api
echo "✅ Бинарный файл установлен"
echo ""

# Копирование конфигурации
echo "⚙️  Копирование конфигурации..."
sudo cp .env /usr/local/etc/yandex-gpt/
sudo cp system_prompt.txt /usr/local/etc/yandex-gpt/

# Обновление пути к промпту в .env
sudo sed -i '' 's|SYSTEM_PROMPT_PATH=system_prompt.txt|SYSTEM_PROMPT_PATH=/usr/local/etc/yandex-gpt/system_prompt.txt|' /usr/local/etc/yandex-gpt/.env

echo "✅ Конфигурация скопирована"
echo ""

# Создание LaunchAgent
echo "📝 Создание LaunchAgent..."

mkdir -p ~/Library/LaunchAgents

cat > ~/Library/LaunchAgents/com.yandex-gpt.api.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.yandex-gpt.api</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/yandex-gpt-api</string>
    </array>
    
    <key>WorkingDirectory</key>
    <string>/usr/local/etc/yandex-gpt</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    
    <key>StandardOutPath</key>
    <string>/usr/local/var/log/yandex-gpt-api.log</string>
    
    <key>StandardErrorPath</key>
    <string>/usr/local/var/log/yandex-gpt-api.error.log</string>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ LaunchAgent создан"
echo ""

# Остановка существующей службы (если запущена)
echo "🔄 Проверка существующей службы..."
if launchctl list | grep -q "com.yandex-gpt.api"; then
    echo "Остановка существующей службы..."
    launchctl stop com.yandex-gpt.api 2>/dev/null || true
    launchctl unload ~/Library/LaunchAgents/com.yandex-gpt.api.plist 2>/dev/null || true
    sleep 2
fi

# Загрузка и запуск службы
echo "🚀 Загрузка и запуск службы..."
launchctl load ~/Library/LaunchAgents/com.yandex-gpt.api.plist
sleep 2

# Проверка статуса
if launchctl list | grep -q "com.yandex-gpt.api"; then
    echo "✅ Служба успешно запущена"
else
    echo "⚠️  Служба загружена, но может потребоваться время для запуска"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "✨ УСТАНОВКА ЗАВЕРШЕНА!"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Информация о службе:"
echo ""
echo "  Статус: launchctl list | grep yandex-gpt"
echo "  Логи:   tail -f /usr/local/var/log/yandex-gpt-api.log"
echo "  Ошибки: tail -f /usr/local/var/log/yandex-gpt-api.error.log"
echo ""
echo "🔧 Управление:"
echo ""
echo "  Остановить:    launchctl stop com.yandex-gpt.api"
echo "  Запустить:     launchctl start com.yandex-gpt.api"
echo "  Перезапустить: launchctl kickstart -k gui/\$(id -u)/com.yandex-gpt.api"
echo "  Отключить:     launchctl unload ~/Library/LaunchAgents/com.yandex-gpt.api.plist"
echo ""

# Проверка доступности API
echo "🔍 Проверка API через 3 секунды..."
sleep 3

if curl -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    echo "✅ API доступен: http://localhost:8080"
    echo ""
    echo "Тестовый запрос:"
    curl -s http://localhost:8080/api/v1/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/api/v1/health
else
    echo "⚠️  API пока недоступен"
    echo ""
    echo "Проверьте логи:"
    echo "  tail -20 /usr/local/var/log/yandex-gpt-api.error.log"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "📚 Подробная документация: DAEMON.md"
echo ""

