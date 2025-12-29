package main

import (
	"log"
	"os"

	"github.com/joho/godotenv"
	"github.com/tabota/yandex-gpt/internal/app"
	"github.com/tabota/yandex-gpt/internal/config"
)

func main() {
	// Загрузка переменных окружения из .env файла
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// Загрузка конфигурации
	cfg := config.Load()

	// Инициализация и запуск приложения
	application := app.New(cfg)

	log.Printf("Starting server on %s:%s", cfg.Server.Host, cfg.Server.Port)

	if err := application.Run(); err != nil {
		log.Fatal("Failed to start server:", err)
		os.Exit(1)
	}
}
