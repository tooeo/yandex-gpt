.PHONY: run build test clean help

# Переменные
APP_NAME=yandex-gpt-api
BUILD_DIR=./bin
CMD_DIR=./cmd/api

help: ## Показать справку
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

run: ## Запустить приложение
	go run $(CMD_DIR)/main.go

build: ## Собрать приложение
	@mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(APP_NAME) $(CMD_DIR)/main.go
	@echo "Build complete: $(BUILD_DIR)/$(APP_NAME)"

test: ## Запустить тесты
	go test -v ./...

test-coverage: ## Запустить тесты с покрытием
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

clean: ## Очистить собранные файлы
	rm -rf $(BUILD_DIR)
	rm -f coverage.out
	@echo "Clean complete"

deps: ## Установить зависимости
	go mod download
	go mod tidy

lint: ## Запустить линтер (требует golangci-lint)
	golangci-lint run

fmt: ## Форматировать код
	go fmt ./...

docker-build: ## Собрать Docker образ
	docker build -t $(APP_NAME):latest .

docker-run: ## Запустить в Docker
	docker run -p 8080:8080 --env-file .env $(APP_NAME):latest

.DEFAULT_GOAL := help





