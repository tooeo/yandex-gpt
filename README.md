# Yandex GPT Tags Generator API

<div align="center">

[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?style=for-the-badge&logo=go)](https://go.dev/)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/yourusername/yandex-gpt?style=for-the-badge)](https://github.com/yourusername/yandex-gpt/releases)

**Интеллектуальная генерация тегов с помощью Yandex GPT API**

[Возможности](#возможности) •
[Установка](#установка-и-запуск) •
[API](#api-endpoints) •
[Демон macOS](#настройка-демона-для-macos) •
[Кастомизация](#кастомизация-системного-промпта) •
[Примеры](#примеры-использования)

</div>

---

## 🚀 Возможности

- ✅ **Интеллектуальная генерация тегов** на основе смысла текста, а не просто ключевых слов
- ✅ **Поддержка существующих тегов** для консистентности проекта
- ✅ **Кастомизация промпта** без перекомпиляции приложения
- ✅ **Гибкие настройки** количества тегов (min/max диапазон)
- ✅ **Дополнительные инструкции** для модели через API
- ✅ **REST API** с простым интерфейсом
- ✅ **Легкое развертывание** - один бинарный файл

## 📋 Требования

- Go 1.21 или выше
- Yandex Cloud аккаунт с доступом к Yandex GPT API
- API ключ и Folder ID из Yandex Cloud

## 📁 Структура проекта

```
yandex-gpt/
├── cmd/
│   └── api/
│       └── main.go           # Точка входа в приложение
├── internal/
│   ├── app/
│   │   └── app.go           # Инициализация приложения и роутинга
│   ├── config/
│   │   └── config.go        # Конфигурация приложения
│   ├── handlers/
│   │   └── tags_handler.go  # HTTP обработчики
│   ├── models/
│   │   └── models.go        # Модели данных
│   └── services/
│       └── yandexgpt.go     # Сервис для работы с Yandex GPT API
├── system_prompt.txt        # Системный промпт для генерации тегов
├── CUSTOM_PROMPT.md         # Документация по кастомизации промпта
├── YANDEX_CLOUD_CHEATSHEET.md # Шпаргалка по Yandex Cloud CLI
├── DAEMON.md                # Документация по демону macOS
├── setup_yandex_cloud.sh    # Скрипт автоматической настройки Yandex Cloud
├── install_daemon_macos.sh  # Скрипт установки демона macOS
├── uninstall_daemon_macos.sh # Скрипт удаления демона macOS
├── .env.example             # Пример файла с переменными окружения
├── go.mod                   # Go модули
└── README.md               # Документация

```

## 🔧 Установка и запуск

### 1. Установите зависимости

```bash
go mod download
```

### 2. Настройте переменные окружения

Скопируйте `.env.example` в `.env` и заполните необходимые параметры:

```bash
cp .env.example .env
```

Отредактируйте `.env`:
```env
SERVER_PORT=8080
SERVER_HOST=localhost

YANDEX_API_KEY=your_api_key_here
YANDEX_FOLDER_ID=your_folder_id_here
YANDEX_GPT_MODEL=yandexgpt-lite
SYSTEM_PROMPT_PATH=system_prompt.txt
```

> **Примечание:** Переменная `SYSTEM_PROMPT_PATH` указывает на файл с системным промптом для генерации тегов. По умолчанию используется `system_prompt.txt` в корне проекта. Вы можете изменить содержимое этого файла без перекомпиляции приложения.

### 3. Запустите приложение

```bash
go run cmd/api/main.go
```

Сервер запустится на `http://localhost:8080`

## 📡 API Endpoints

### Health Check

```http
GET /api/v1/health
```

**Ответ:**
```json
{
  "status": "ok",
  "message": "Service is running"
}
```

### Tags (Генерация тегов)

Генерирует релевантные теги для текста. Поддерживает использование существующих тегов проекта для консистентности.

> **Кастомизация промпта:** Системный промпт для генерации тегов находится в файле `system_prompt.txt` (или по пути, указанному в `SYSTEM_PROMPT_PATH`). Вы можете редактировать этот файл для изменения поведения генерации тегов без перекомпиляции приложения. Файл поддерживает переменные `{min_tags}` и `{max_tags}`, которые автоматически заменяются на соответствующие значения.

```http
POST /api/v1/tags
```

**Тело запроса:**
```json
{
  "text": "This is a comprehensive guide about building REST APIs using Golang. We will cover HTTP handlers, routing, middleware, and database integration with PostgreSQL.",
  "min_tags": 3,
  "max_tags": 7,
  "existing_tags": ["golang", "api", "database", "docker", "kubernetes"]
}
```

**Параметры:**
- `text` (required, string): Текст для анализа
- `num_tags` (optional, int): Фиксированное количество тегов (по умолчанию: 5)
- `min_tags` (optional, int): Минимальное количество тегов (по умолчанию: 3)
- `max_tags` (optional, int): Максимальное количество тегов (по умолчанию: 5)
- `existing_tags` (optional, array): Список существующих тегов проекта. Модель будет предпочитать использовать их, если они релевантны
- `custom_prompt` (optional, string): Дополнительные инструкции для модели

**Ответ:**
```json
{
  "tags": ["golang", "api", "rest", "postgresql", "database"]
}
```

**Пример с фиксированным количеством:**
```json
{
  "text": "Machine learning algorithms for image recognition and computer vision applications.",
  "num_tags": 3
}
```

**Ответ:**
```json
{
  "tags": ["machine-learning", "computer-vision", "image-recognition"]
}
```

## Параметры запросов

### Tags (Генерация тегов)

- `text` (required, string): Текст для анализа и генерации тегов
- `num_tags` (optional, int): Фиксированное количество тегов (для обратной совместимости, по умолчанию: 5)
- `min_tags` (optional, int): Минимальное количество тегов (по умолчанию: 3)
- `max_tags` (optional, int): Максимальное количество тегов (по умолчанию: 5)
- `existing_tags` (optional, array of strings): Существующие теги проекта. Модель будет предпочитать их использовать, если они релевантны содержанию
- `custom_prompt` (optional, string): Дополнительные инструкции для модели

**Примечание:** Если указан `num_tags`, то `min_tags` и `max_tags` игнорируются, и генерируется фиксированное количество тегов.

## Примеры использования

### С помощью curl

#### Health Check
```bash
curl http://localhost:8080/api/v1/health
```

#### Tags (Простой запрос)
```bash
curl -X POST http://localhost:8080/api/v1/tags \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Building microservices with Go and Docker containers",
    "num_tags": 5
  }'
```

#### Tags (С диапазоном и существующими тегами)
```bash
curl -X POST http://localhost:8080/api/v1/tags \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This guide covers REST API development using Golang, PostgreSQL database integration, and deployment with Docker",
    "min_tags": 3,
    "max_tags": 7,
    "existing_tags": ["golang", "docker", "kubernetes", "api", "postgresql"]
  }'
```

#### Tags (С кастомными инструкциями)
```bash
curl -X POST http://localhost:8080/api/v1/tags \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Machine learning tutorial for beginners",
    "num_tags": 5,
    "custom_prompt": "Focus on educational and beginner-friendly tags"
  }'
```

## Кастомизация системного промпта

Системный промпт для генерации тегов вынесен в отдельный файл, который можно редактировать без перекомпиляции приложения. Подробнее см. [CUSTOM_PROMPT.md](CUSTOM_PROMPT.md).

**Быстрый старт:**
1. Отредактируйте файл `system_prompt.txt`
2. Перезапустите приложение
3. Новый промпт будет применяться ко всем запросам

## 💡 Примеры использования

### Структура кода

- **cmd/api** - точка входа приложения
- **internal/app** - инициализация приложения, middleware, роутинг
- **internal/config** - конфигурация из переменных окружения
- **internal/handlers** - HTTP обработчики для tags endpoint
- **internal/models** - модели данных для запросов и ответов
- **internal/services** - бизнес-логика и интеграции с Yandex GPT API
- **system_prompt.txt** - системный промпт для генерации тегов (редактируемый)

### Компиляция

```bash
# Сборка бинарника
go build -o bin/yandex-gpt-api cmd/api/main.go

# Запуск
./bin/yandex-gpt-api
```

### Использование Makefile

```bash
# Сборка
make build

# Запуск
make run

# Очистка
make clean
```

## 🔄 Настройка демона для macOS

### Быстрая установка (рекомендуется)

Используйте автоматический скрипт установки:

```bash
./install_daemon_macos.sh
```

Скрипт автоматически:
- ✅ Соберет бинарный файл (если нужно)
- ✅ Скопирует файлы в системные директории
- ✅ Создаст LaunchAgent
- ✅ Запустит службу
- ✅ Проверит работоспособность

### Ручная установка

Или настройте всё вручную:

#### 1. Соберите бинарный файл

```bash
go build -o bin/yandex-gpt-api cmd/api/main.go
```

#### 2. Скопируйте файлы в системные директории

```bash
# Создайте необходимые директории
sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/local/etc/yandex-gpt
sudo mkdir -p /usr/local/var/log

# Скопируйте бинарный файл
sudo cp bin/yandex-gpt-api /usr/local/bin/
sudo chmod +x /usr/local/bin/yandex-gpt-api

# Скопируйте конфигурационные файлы
sudo cp .env /usr/local/etc/yandex-gpt/
sudo cp system_prompt.txt /usr/local/etc/yandex-gpt/

# Обновите путь к промпту в .env
sudo sed -i '' 's|SYSTEM_PROMPT_PATH=system_prompt.txt|SYSTEM_PROMPT_PATH=/usr/local/etc/yandex-gpt/system_prompt.txt|' /usr/local/etc/yandex-gpt/.env
```

#### 3. Создайте LaunchAgent

Создайте файл `~/Library/LaunchAgents/com.yandex-gpt.api.plist`:

```bash
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
```

#### 4. Загрузите и запустите службу

```bash
# Загрузить службу
launchctl load ~/Library/LaunchAgents/com.yandex-gpt.api.plist

# Запустить службу
launchctl start com.yandex-gpt.api

# Проверить статус
launchctl list | grep yandex-gpt
```

#### 5. Управление службой

```bash
# Остановить службу
launchctl stop com.yandex-gpt.api

# Выгрузить службу (отключить автозапуск)
launchctl unload ~/Library/LaunchAgents/com.yandex-gpt.api.plist

# Перезапустить службу
launchctl unload ~/Library/LaunchAgents/com.yandex-gpt.api.plist
launchctl load ~/Library/LaunchAgents/com.yandex-gpt.api.plist
```

#### 6. Просмотр логов

```bash
# Просмотр стандартного вывода
tail -f /usr/local/var/log/yandex-gpt-api.log

# Просмотр ошибок
tail -f /usr/local/var/log/yandex-gpt-api.error.log

# Последние 50 строк
tail -50 /usr/local/var/log/yandex-gpt-api.log
```

#### 7. Проверка работы

```bash
# Проверить, что служба запущена
curl http://localhost:8080/api/v1/health

# Проверить статус в launchctl
launchctl list | grep yandex-gpt

# Посмотреть логи запуска
cat /usr/local/var/log/yandex-gpt-api.log
```

### Удаление службы

**Автоматически:**

```bash
./uninstall_daemon_macos.sh
```

**Вручную:**

```bash
# Остановить и выгрузить службу
launchctl stop com.yandex-gpt.api
launchctl unload ~/Library/LaunchAgents/com.yandex-gpt.api.plist

# Удалить файлы
rm ~/Library/LaunchAgents/com.yandex-gpt.api.plist
sudo rm /usr/local/bin/yandex-gpt-api
sudo rm -rf /usr/local/etc/yandex-gpt
sudo rm /usr/local/var/log/yandex-gpt-api*.log
```

> **💡 Совет:** После обновления бинарного файла не забудьте перезапустить службу

> **📚 Подробнее:** См. [DAEMON.md](DAEMON.md) для детальной документации по демону

## 🔑 Получение API ключа и настройка Yandex Cloud

### 🚀 Быстрая настройка (рекомендуется)

Используйте автоматический скрипт для настройки:

```bash
# Запустите интерактивный скрипт настройки
./setup_yandex_cloud.sh
```

Скрипт автоматически:
- ✅ Проверит установку Yandex Cloud CLI
- ✅ Получит Folder ID
- ✅ Создаст Service Account (если нужно)
- ✅ Назначит необходимые роли
- ✅ Создаст API ключ
- ✅ Сгенерирует `.env` файл с вашими данными

### 📋 Ручная настройка (подробная инструкция)

Если хотите настроить всё вручную или понять процесс детально:

### Предварительные требования

1. Аккаунт в Yandex Cloud
2. Установленный [Yandex Cloud CLI](https://cloud.yandex.ru/docs/cli/quickstart)

### Шаг 1: Установка Yandex Cloud CLI

**macOS/Linux:**
```bash
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

**Windows (PowerShell):**
```powershell
iex (New-Object System.Net.WebClient).DownloadString('https://storage.yandexcloud.net/yandexcloud-yc/install.ps1')
```

После установки перезапустите терминал и проверьте:
```bash
yc --version
```

### Шаг 2: Инициализация CLI

```bash
# Авторизация
yc init
```

Следуйте инструкциям:
1. Получите OAuth токен по ссылке
2. Выберите облако (cloud)
3. Выберите или создайте каталог (folder)

### Шаг 3: Получение Folder ID

```bash
# Получить список каталогов
yc resource-manager folder list

# Сохранить folder-id в переменную (замените на ваш folder name)
export YC_FOLDER_ID=$(yc resource-manager folder get <folder-name> --format json | jq -r '.id')

# Или просто скопируйте ID из вывода команды list
echo $YC_FOLDER_ID
```

**Пример вывода:**
```
+----------------------+-------------+--------+--------+
|          ID          |    NAME     | LABELS | STATUS |
+----------------------+-------------+--------+--------+
| b1g8dn6s8v9k2j3h4m5n | my-folder   |        | ACTIVE |
+----------------------+-------------+--------+--------+
```

Скопируйте значение из колонки **ID**.

### Шаг 4: Создание Service Account

```bash
# Создать service account
yc iam service-account create --name yandex-gpt-sa \
  --description "Service account for Yandex GPT API"

# Получить ID service account
export SA_ID=$(yc iam service-account get yandex-gpt-sa --format json | jq -r '.id')

# Назначить роль для работы с GPT
yc resource-manager folder add-access-binding <folder-name-or-id> \
  --role ai.languageModels.user \
  --subject serviceAccount:$SA_ID
```

### Шаг 5: Создание API ключа

```bash
# Создать API ключ
yc iam api-key create \
  --service-account-name yandex-gpt-sa \
  --description "API key for GPT Tags Generator"

# Сохраните API ключ! Он показывается только один раз
```

**Пример вывода:**
```yaml
api_key:
  id: ajek8t9k2j3h4m5n6p7q
  service_account_id: aje8dn6s8v9k2j3h4m5n
  created_at: "2024-12-29T10:30:00Z"
  description: API key for GPT Tags Generator
  key_id: AQVN1a2b3c4d5e6f7g8h
secret: AQVNxxx_your_secret_key_here_xxxxxxxxxxxxxxxxxxxxx
```

**ВАЖНО:** Скопируйте значение поля `secret` - это ваш API ключ!

### Шаг 6: Настройка .env файла

```bash
# Перейдите в директорию проекта
cd /path/to/yandex-gpt

# Создайте .env из примера
cp .env.example .env

# Отредактируйте .env
nano .env
```

Вставьте ваши данные:
```env
# Server Configuration
SERVER_PORT=8080
SERVER_HOST=localhost

# Yandex GPT API Configuration
YANDEX_API_KEY=AQVNxxx_your_secret_key_here_xxxxxxxxxxxxxxxxxxxxx
YANDEX_FOLDER_ID=b1g8dn6s8v9k2j3h4m5n
YANDEX_GPT_MODEL=yandexgpt-lite

# System Prompt Configuration
SYSTEM_PROMPT_PATH=system_prompt.txt
```

### Шаг 7: Проверка настройки

```bash
# Проверка через CLI
yc yandex-gpt create-completion \
  --folder-id $YC_FOLDER_ID \
  --model yandexgpt-lite \
  --temperature 0.6 \
  --max-tokens 100 \
  --message role=user,text="Привет"

# Запустить приложение
go run cmd/api/main.go

# В другом терминале - тестовый запрос
curl http://localhost:8080/api/v1/health
```

### Быстрая команда для получения всех параметров

```bash
#!/bin/bash
# Скрипт для быстрого получения всех необходимых параметров

echo "📋 Сбор информации о Yandex Cloud..."
echo ""

# Folder ID
echo "🗂️  Folder ID:"
yc config get folder-id
echo ""

# Service Accounts
echo "👤 Service Accounts:"
yc iam service-account list
echo ""

# API Keys
echo "🔑 API Keys для service account:"
read -p "Введите имя service account: " SA_NAME
yc iam api-key list --service-account-name "$SA_NAME"
echo ""

echo "✅ Для создания нового API ключа выполните:"
echo "yc iam api-key create --service-account-name $SA_NAME"
```

Сохраните этот скрипт как `get_yc_config.sh` и запустите:
```bash
chmod +x get_yc_config.sh
./get_yc_config.sh
```

### Альтернативный способ (через веб-интерфейс)

1. **Перейдите в [Yandex Cloud Console](https://console.cloud.yandex.ru/)**

2. **Выберите каталог:**
   - В левом верхнем углу выберите нужный каталог
   - Скопируйте Folder ID из URL: `https://console.cloud.yandex.ru/folders/b1g...`

3. **Создайте Service Account:**
   - Перейдите: **IAM** → **Сервисные аккаунты**
   - Нажмите **Создать сервисный аккаунт**
   - Имя: `yandex-gpt-sa`
   - Роль: `ai.languageModels.user`

4. **Создайте API ключ:**
   - Откройте созданный Service Account
   - Нажмите **Создать новый ключ** → **Создать API-ключ**
   - Скопируйте и сохраните ключ

### Выбор модели

Доступные модели:
- `yandexgpt-lite` - быстрая и экономичная (рекомендуется для тегов)
- `yandexgpt` - стандартная модель с лучшим качеством
- `yandexgpt-32k` - расширенный контекст

Укажите нужную модель в `.env`:
```env
YANDEX_GPT_MODEL=yandexgpt-lite
```

### Проверка квот и лимитов

```bash
# Проверить квоты
yc yandex-gpt get-quotas --folder-id $YC_FOLDER_ID

# Проверить доступность API
curl -H "Authorization: Api-Key $YANDEX_API_KEY" \
     -H "x-folder-id: $YC_FOLDER_ID" \
     https://llm.api.cloud.yandex.net/foundationModels/v1/completion \
     -d '{"modelUri":"gpt://'$YC_FOLDER_ID'/yandexgpt-lite/latest","messages":[{"role":"user","text":"test"}]}'
```

### Устранение проблем

**Ошибка "Permission denied":**
```bash
# Проверьте роли service account
yc resource-manager folder list-access-bindings <folder-id> | grep $SA_ID

# Добавьте роль, если её нет
yc resource-manager folder add-access-binding <folder-id> \
  --role ai.languageModels.user \
  --subject serviceAccount:$SA_ID
```

**Ошибка "Invalid API key":**
- Убедитесь, что скопировали весь ключ (начинается с `AQVN...`)
- Проверьте, что нет лишних пробелов в `.env`
- Пересоздайте API ключ при необходимости

**Ошибка "Folder not found":**
```bash
# Проверьте правильность folder-id
yc resource-manager folder get <folder-id>
```

### Полезные ссылки

- [Официальная документация Yandex GPT](https://cloud.yandex.ru/docs/yandexgpt/)
- [Управление API ключами](https://cloud.yandex.ru/docs/iam/operations/api-key/create)
- [Роли для работы с YandexGPT](https://cloud.yandex.ru/docs/yandexgpt/security/)
- [Тарифы и квоты](https://cloud.yandex.ru/docs/yandexgpt/pricing)

### 📚 Дополнительно

Полная шпаргалка по всем командам Yandex Cloud CLI: [YANDEX_CLOUD_CHEATSHEET.md](YANDEX_CLOUD_CHEATSHEET.md)

---

Подробная инструкция: [Yandex Cloud Documentation](https://cloud.yandex.ru/docs/iam/operations/api-key/create)

## 🤝 Contributing

Мы приветствуем вклад в проект! См. [CONTRIBUTING.md](CONTRIBUTING.md) для деталей.

## 📝 License

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

## 🙏 Благодарности

- [Yandex Cloud](https://cloud.yandex.ru/) за предоставление GPT API
- [Gorilla Mux](https://github.com/gorilla/mux) за отличный роутер

## 📮 Контакты

Если у вас есть вопросы или предложения, пожалуйста:
- Откройте [Issue](https://github.com/yourusername/yandex-gpt/issues)
- Создайте [Pull Request](https://github.com/yourusername/yandex-gpt/pulls)

---

<div align="center">
Made with ❤️ using Golang and Yandex GPT
</div>
