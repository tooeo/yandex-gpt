package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/tabota/yandex-gpt/internal/models"
	"github.com/tabota/yandex-gpt/internal/services"
)

// TagsHandler обработчик для генерации тегов
type TagsHandler struct {
	service *services.YandexGPTService
}

// NewTagsHandler создает новый обработчик
func NewTagsHandler(service *services.YandexGPTService) *TagsHandler {
	return &TagsHandler{
		service: service,
	}
}

// Tags генерирует теги для текста
func (h *TagsHandler) Tags(w http.ResponseWriter, r *http.Request) {
	var req models.TagsRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondWithTagsError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.Text == "" {
		respondWithTagsError(w, http.StatusBadRequest, "Text is required")
		return
	}

	// Определяем диапазон тегов
	minTags := req.MinTags
	maxTags := req.MaxTags

	// Если указан num_tags (старый формат), используем его как фиксированное значение
	if req.NumTags > 0 {
		minTags = req.NumTags
		maxTags = req.NumTags
	}

	// Устанавливаем значения по умолчанию
	if minTags <= 0 {
		minTags = 3
	}
	if maxTags <= 0 {
		maxTags = 5
	}

	// Валидация: min не может быть больше max
	if minTags > maxTags {
		minTags, maxTags = maxTags, minTags // Меняем местами
	}

	// Генерация тегов
	result, err := h.service.GenerateTags(req.Text, minTags, maxTags, req.ExistingTags, req.CustomPrompt)
	if err != nil {
		respondWithTagsError(w, http.StatusInternalServerError, err.Error())
		return
	}

	// Парсинг тегов из ответа (разделение по запятым и очистка)
	tags := parseTags(result)

	respondWithJSON(w, http.StatusOK, models.TagsResponse{
		Tags: tags,
	})
}

// parseTags парсит строку с тегами и возвращает слайс очищенных тегов
func parseTags(tagsString string) []string {
	// Удаляем лишние пробелы и разбиваем по запятым
	parts := strings.Split(tagsString, ",")
	tags := make([]string, 0, len(parts))

	for _, tag := range parts {
		// Очищаем каждый тег от пробелов и переносов строк
		cleaned := strings.TrimSpace(tag)
		cleaned = strings.ToLower(cleaned)
		// Удаляем возможные кавычки
		cleaned = strings.Trim(cleaned, "\"'")

		// Заменяем пробелы на дефисы
		cleaned = strings.ReplaceAll(cleaned, " ", "-")

		if cleaned != "" {
			tags = append(tags, cleaned)
		}
	}

	return tags
}

// respondWithTagsError отправляет ошибку для tags endpoint
func respondWithTagsError(w http.ResponseWriter, code int, message string) {
	respondWithJSON(w, code, models.TagsResponse{
		Error: message,
	})
}

// HealthCheck проверка работоспособности сервиса
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	respondWithJSON(w, http.StatusOK, map[string]string{
		"status":  "ok",
		"message": "Service is running",
	})
}

// respondWithJSON отправляет JSON ответ
func respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	response, err := json.Marshal(payload)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		//nolint:errcheck // Игнорируем ошибку записи, т.к. уже обрабатываем ошибку маршалинга
		w.Write([]byte("Internal Server Error"))
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	//nolint:errcheck // Игнорируем ошибку записи, т.к. нет способа корректно обработать отключение клиента
	w.Write(response)
}
