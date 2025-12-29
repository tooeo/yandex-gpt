package app

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"github.com/tabota/yandex-gpt/internal/config"
	"github.com/tabota/yandex-gpt/internal/handlers"
	"github.com/tabota/yandex-gpt/internal/services"
)

// App представляет приложение
type App struct {
	config  *config.Config
	router  *mux.Router
	service *services.YandexGPTService
}

// New создает новый экземпляр приложения
func New(cfg *config.Config) *App {
	app := &App{
		config: cfg,
		router: mux.NewRouter(),
	}

	// Инициализация сервиса YandexGPT
	app.service = services.NewYandexGPTService(
		cfg.YandexGPT.APIKey,
		cfg.YandexGPT.FolderID,
		cfg.YandexGPT.Model,
		cfg.YandexGPT.SystemPromptPath,
	)

	// Настройка роутов
	app.setupRoutes()

	return app
}

// setupRoutes настраивает маршруты приложения
func (a *App) setupRoutes() {
	// Создание обработчика
	handler := handlers.NewTagsHandler(a.service)

	// API маршруты
	api := a.router.PathPrefix("/api/v1").Subrouter()

	// Health check
	api.HandleFunc("/health", handlers.HealthCheck).Methods("GET", "OPTIONS")

	// Tags endpoint
	api.HandleFunc("/tags", handler.Tags).Methods("POST", "OPTIONS")

	// Middleware
	a.router.Use(loggingMiddleware)
	a.router.Use(corsMiddleware)
}

// Run запускает HTTP сервер
func (a *App) Run() error {
	addr := fmt.Sprintf("%s:%s", a.config.Server.Host, a.config.Server.Port)
	return http.ListenAndServe(addr, a.router)
}

// loggingMiddleware логирует входящие запросы
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		fmt.Printf("[%s] %s %s - %v\n", r.Method, r.URL.Path, r.RemoteAddr, time.Since(start))
	})
}

// corsMiddleware добавляет CORS заголовки
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
