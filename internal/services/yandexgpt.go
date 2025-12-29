package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/tabota/yandex-gpt/internal/models"
)

const (
	yandexGPTURL = "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"
)

// YandexGPTService сервис для работы с Yandex GPT API
type YandexGPTService struct {
	apiKey           string
	folderID         string
	model            string
	systemPromptPath string
	client           *http.Client
}

// NewYandexGPTService создает новый экземпляр сервиса
func NewYandexGPTService(apiKey, folderID, model, systemPromptPath string) *YandexGPTService {
	return &YandexGPTService{
		apiKey:           apiKey,
		folderID:         folderID,
		model:            model,
		systemPromptPath: systemPromptPath,
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// GenerateTags генерирует теги для текста
func (s *YandexGPTService) GenerateTags(text string, minTags, maxTags int, existingTags []string, customPrompt string) (string, error) {
	// Установка значений по умолчанию
	if minTags <= 0 {
		minTags = 3
	}
	if maxTags <= 0 {
		maxTags = 5
	}
	if minTags > maxTags {
		minTags, maxTags = maxTags, minTags
	}

	// Загрузка системного промпта из файла
	systemPrompt, err := s.loadSystemPrompt(minTags, maxTags)
	if err != nil {
		return "", fmt.Errorf("failed to load system prompt: %w", err)
	}

	// Добавляем пользовательский промпт, если он есть
	if customPrompt != "" {
		systemPrompt += fmt.Sprintf(`

ADDITIONAL USER INSTRUCTIONS:
%s`, customPrompt)
	}

	// Если есть существующие теги, добавляем информацию о них
	var userPrompt string
	if len(existingTags) > 0 {
		userPrompt = fmt.Sprintf(`Text to analyze:
%s

Existing project tags (prefer using these if they are truly relevant):
%s

Generate between %d and %d tags. Prioritize existing tags if they fit the content, but create new ones if needed. Remember: quality over quantity!`,
			text,
			strings.Join(existingTags, ", "),
			minTags,
			maxTags)
	} else {
		userPrompt = text
	}

	messages := []models.YandexGPTMessage{
		{
			Role: "system",
			Text: systemPrompt,
		},
		{
			Role: "user",
			Text: userPrompt,
		},
	}

	// Отправляем запрос с низкой температурой для более точных результатов
	return s.sendRequest(messages, 0.3, 500)
}

// loadSystemPrompt загружает системный промпт из файла и подставляет параметры
func (s *YandexGPTService) loadSystemPrompt(minTags, maxTags int) (string, error) {
	// Читаем файл с промптом
	content, err := os.ReadFile(s.systemPromptPath)
	if err != nil {
		return "", fmt.Errorf("failed to read system prompt file: %w", err)
	}

	// Подставляем параметры в промпт
	prompt := string(content)
	prompt = strings.ReplaceAll(prompt, "{min_tags}", fmt.Sprintf("%d", minTags))
	prompt = strings.ReplaceAll(prompt, "{max_tags}", fmt.Sprintf("%d", maxTags))

	return prompt, nil
}

// sendRequest отправляет запрос к Yandex GPT API
func (s *YandexGPTService) sendRequest(messages []models.YandexGPTMessage, temperature float64, maxTokens int) (string, error) {
	// Установка значений по умолчанию
	if temperature == 0 {
		temperature = 0.6
	}
	if maxTokens == 0 {
		maxTokens = 2000
	}

	// Формирование URI модели
	modelURI := fmt.Sprintf("gpt://%s/%s/latest", s.folderID, s.model)

	// Создание запроса
	requestBody := models.YandexGPTCompletionRequest{
		ModelURI: modelURI,
		CompletionOptions: models.YandexGPTCompletionOptions{
			Stream:      false,
			Temperature: temperature,
			MaxTokens:   maxTokens,
		},
		Messages: messages,
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	// Создание HTTP запроса
	req, err := http.NewRequest("POST", yandexGPTURL, bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	// Установка заголовков (как в статье)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Api-Key %s", s.apiKey))
	req.Header.Set("x-folder-id", s.folderID) // Обязательный заголовок!

	// Отправка запроса
	resp, err := s.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Чтение ответа
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	// Проверка статуса ответа
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("API returned error status %d: %s", resp.StatusCode, string(body))
	}

	// Парсинг ответа
	var yandexResp models.YandexGPTResponse
	if err := json.Unmarshal(body, &yandexResp); err != nil {
		return "", fmt.Errorf("failed to unmarshal response: %w", err)
	}

	// Извлечение текста из ответа
	if len(yandexResp.Result.Alternatives) > 0 {
		return yandexResp.Result.Alternatives[0].Message.Text, nil
	}

	return "", fmt.Errorf("no alternatives in response")
}
