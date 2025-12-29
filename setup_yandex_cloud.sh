#!/bin/bash

# Скрипт для получения конфигурации Yandex Cloud

set -e

echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║   🔧 Yandex Cloud Configuration Helper                           ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

# Проверка установки yc CLI
if ! command -v yc &> /dev/null; then
    echo "❌ Yandex Cloud CLI не установлен!"
    echo ""
    echo "Установите его:"
    echo "  macOS/Linux: curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash"
    echo "  Windows: iex (New-Object System.Net.WebClient).DownloadString('https://storage.yandexcloud.net/yandexcloud-yc/install.ps1')"
    echo ""
    exit 1
fi

echo "✅ Yandex Cloud CLI установлен"
echo ""

# Проверка авторизации
if ! yc config list &> /dev/null; then
    echo "❌ Вы не авторизованы в Yandex Cloud!"
    echo ""
    echo "Выполните: yc init"
    echo ""
    exit 1
fi

echo "✅ Авторизация выполнена"
echo ""

# Получение Folder ID
echo "═══════════════════════════════════════════════════════════════════"
echo "📁 FOLDER ID"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

FOLDER_ID=$(yc config get folder-id 2>/dev/null)
if [ -z "$FOLDER_ID" ]; then
    echo "⚠️  Folder ID не настроен в конфиге"
    echo ""
    echo "Доступные каталоги:"
    yc resource-manager folder list
    echo ""
    read -p "Введите ID каталога: " FOLDER_ID
else
    echo "Текущий Folder ID: $FOLDER_ID"
    FOLDER_NAME=$(yc resource-manager folder get $FOLDER_ID --format json 2>/dev/null | jq -r '.name')
    echo "Имя каталога: $FOLDER_NAME"
fi

echo ""

# Service Accounts
echo "═══════════════════════════════════════════════════════════════════"
echo "👤 SERVICE ACCOUNTS"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

SA_LIST=$(yc iam service-account list --folder-id $FOLDER_ID --format json 2>/dev/null)
SA_COUNT=$(echo "$SA_LIST" | jq '. | length')

if [ "$SA_COUNT" -eq 0 ]; then
    echo "⚠️  Service account'ы не найдены"
    echo ""
    read -p "Создать новый service account 'yandex-gpt-sa'? (y/n): " CREATE_SA
    
    if [ "$CREATE_SA" = "y" ]; then
        echo ""
        echo "Создаем service account..."
        yc iam service-account create \
            --folder-id $FOLDER_ID \
            --name yandex-gpt-sa \
            --description "Service account for Yandex GPT Tags Generator"
        
        SA_ID=$(yc iam service-account get yandex-gpt-sa --folder-id $FOLDER_ID --format json | jq -r '.id')
        
        echo ""
        echo "Назначаем роль ai.languageModels.user..."
        yc resource-manager folder add-access-binding $FOLDER_ID \
            --role ai.languageModels.user \
            --subject serviceAccount:$SA_ID
        
        echo "✅ Service account создан: yandex-gpt-sa"
        SA_NAME="yandex-gpt-sa"
    else
        echo "Создайте service account вручную и запустите скрипт снова"
        exit 1
    fi
else
    echo "Найдено service account'ов: $SA_COUNT"
    echo ""
    yc iam service-account list --folder-id $FOLDER_ID
    echo ""
    
    read -p "Введите имя service account для работы с GPT: " SA_NAME
    
    # Проверка существования
    SA_ID=$(yc iam service-account get $SA_NAME --folder-id $FOLDER_ID --format json 2>/dev/null | jq -r '.id')
    if [ -z "$SA_ID" ] || [ "$SA_ID" = "null" ]; then
        echo "❌ Service account '$SA_NAME' не найден"
        exit 1
    fi
fi

echo ""

# Проверка ролей
echo "═══════════════════════════════════════════════════════════════════"
echo "🔐 ПРОВЕРКА РОЛЕЙ"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

ROLES=$(yc resource-manager folder list-access-bindings $FOLDER_ID --format json | \
    jq -r ".[] | select(.subject.id == \"$SA_ID\") | .role_id")

if echo "$ROLES" | grep -q "ai.languageModels.user"; then
    echo "✅ Роль ai.languageModels.user назначена"
else
    echo "⚠️  Роль ai.languageModels.user НЕ назначена"
    echo ""
    read -p "Назначить роль? (y/n): " ASSIGN_ROLE
    
    if [ "$ASSIGN_ROLE" = "y" ]; then
        yc resource-manager folder add-access-binding $FOLDER_ID \
            --role ai.languageModels.user \
            --subject serviceAccount:$SA_ID
        echo "✅ Роль назначена"
    fi
fi

echo ""

# API Keys
echo "═══════════════════════════════════════════════════════════════════"
echo "🔑 API KEYS"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

API_KEYS=$(yc iam api-key list --service-account-name $SA_NAME --folder-id $FOLDER_ID --format json 2>/dev/null)
API_KEY_COUNT=$(echo "$API_KEYS" | jq '. | length')

if [ "$API_KEY_COUNT" -eq 0 ]; then
    echo "⚠️  API ключи не найдены"
else
    echo "Найдено API ключей: $API_KEY_COUNT"
    echo ""
    yc iam api-key list --service-account-name $SA_NAME --folder-id $FOLDER_ID
fi

echo ""
read -p "Создать новый API ключ? (y/n): " CREATE_KEY

if [ "$CREATE_KEY" = "y" ]; then
    echo ""
    echo "Создаем API ключ..."
    API_KEY_OUTPUT=$(yc iam api-key create \
        --service-account-name $SA_NAME \
        --folder-id $FOLDER_ID \
        --description "API key for GPT Tags Generator - $(date +%Y-%m-%d)" \
        --format json)
    
    API_KEY_SECRET=$(echo "$API_KEY_OUTPUT" | jq -r '.secret')
    
    echo ""
    echo "✅ API ключ создан!"
    echo ""
    echo "⚠️  ВАЖНО: Сохраните этот ключ! Он показывается только один раз:"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$API_KEY_SECRET"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo ""
    echo "ℹ️  Используйте существующий API ключ"
    API_KEY_SECRET="<your_existing_api_key>"
fi

echo ""

# Генерация .env файла
echo "═══════════════════════════════════════════════════════════════════"
echo "📝 ГЕНЕРАЦИЯ .env ФАЙЛА"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

read -p "Создать/обновить .env файл? (y/n): " CREATE_ENV

if [ "$CREATE_ENV" = "y" ]; then
    cat > .env << EOF
# Server Configuration
SERVER_PORT=8080
SERVER_HOST=localhost

# Yandex GPT API Configuration
YANDEX_API_KEY=$API_KEY_SECRET
YANDEX_FOLDER_ID=$FOLDER_ID
YANDEX_GPT_MODEL=yandexgpt-lite

# System Prompt Configuration
SYSTEM_PROMPT_PATH=system_prompt.txt
EOF
    
    chmod 600 .env
    
    echo "✅ Файл .env создан"
    echo ""
    
    if [ "$API_KEY_SECRET" = "<your_existing_api_key>" ]; then
        echo "⚠️  Не забудьте вставить ваш существующий API ключ в .env!"
    fi
fi

echo ""

# Итоговая информация
echo "═══════════════════════════════════════════════════════════════════"
echo "✨ ГОТОВО!"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "📋 Ваша конфигурация:"
echo ""
echo "  Folder ID:       $FOLDER_ID"
echo "  Service Account: $SA_NAME"
echo "  SA ID:           $SA_ID"
echo "  Model:           yandexgpt-lite"
echo ""
echo "🚀 Следующие шаги:"
echo ""
echo "  1. Проверьте файл .env"
echo "  2. Запустите: go run cmd/api/main.go"
echo "  3. Протестируйте: curl http://localhost:8080/api/v1/health"
echo ""
echo "═══════════════════════════════════════════════════════════════════"

