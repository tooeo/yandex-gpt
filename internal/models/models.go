package models

// TagsRequest запрос на генерацию тегов
type TagsRequest struct {
	Text         string   `json:"text"`
	NumTags      int      `json:"num_tags,omitempty"`      // Фиксированное количество (для обратной совместимости)
	MinTags      int      `json:"min_tags,omitempty"`      // Минимальное количество тегов
	MaxTags      int      `json:"max_tags,omitempty"`      // Максимальное количество тегов
	ExistingTags []string `json:"existing_tags,omitempty"` // Существующие теги проекта
	CustomPrompt string   `json:"custom_prompt,omitempty"` // Пользовательские инструкции для модели
}

// TagsResponse ответ с тегами
type TagsResponse struct {
	Tags  []string `json:"tags"`
	Error string   `json:"error,omitempty"`
}

// YandexGPTCompletionRequest структура запроса к Yandex GPT API
type YandexGPTCompletionRequest struct {
	ModelURI          string                     `json:"modelUri"`
	CompletionOptions YandexGPTCompletionOptions `json:"completionOptions"`
	Messages          []YandexGPTMessage         `json:"messages"`
}

// YandexGPTCompletionOptions опции для генерации
type YandexGPTCompletionOptions struct {
	Stream      bool    `json:"stream"`
	Temperature float64 `json:"temperature"`
	MaxTokens   int     `json:"maxTokens"`
}

// YandexGPTMessage сообщение для Yandex GPT
type YandexGPTMessage struct {
	Role string `json:"role"`
	Text string `json:"text"`
}

// YandexGPTResponse ответ от Yandex GPT API
type YandexGPTResponse struct {
	Result struct {
		Alternatives []struct {
			Message struct {
				Role string `json:"role"`
				Text string `json:"text"`
			} `json:"message"`
			Status string `json:"status"`
		} `json:"alternatives"`
		Usage struct {
			InputTextTokens  interface{} `json:"inputTextTokens"`
			CompletionTokens interface{} `json:"completionTokens"`
			TotalTokens      interface{} `json:"totalTokens"`
		} `json:"usage"`
		ModelVersion string `json:"modelVersion"`
	} `json:"result"`
}
