package config

import (
	"os"
)

// Config содержит конфигурацию приложения
type Config struct {
	Server    ServerConfig
	YandexGPT YandexGPTConfig
}

// ServerConfig конфигурация HTTP сервера
type ServerConfig struct {
	Host string
	Port string
}

// YandexGPTConfig конфигурация для Yandex GPT API
type YandexGPTConfig struct {
	APIKey           string
	FolderID         string
	Model            string
	SystemPromptPath string
}

// Load загружает конфигурацию из переменных окружения
func Load() *Config {
	return &Config{
		Server: ServerConfig{
			Host: getEnv("SERVER_HOST", "localhost"),
			Port: getEnv("SERVER_PORT", "8080"),
		},
		YandexGPT: YandexGPTConfig{
			APIKey:           getEnv("YANDEX_API_KEY", ""),
			FolderID:         getEnv("YANDEX_FOLDER_ID", ""),
			Model:            getEnv("YANDEX_GPT_MODEL", "yandexgpt-lite"),
			SystemPromptPath: getEnv("SYSTEM_PROMPT_PATH", "system_prompt.txt"),
		},
	}
}

// getEnv получает значение переменной окружения или возвращает значение по умолчанию
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
