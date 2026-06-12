package api

import (
	"net/http"

	"live_sessions_api/internal/service"
)

func NewRouter(svc service.LiveSessionService) http.Handler {
	handler := NewHandler(svc)
	mux := http.NewServeMux()

	mux.HandleFunc("GET /healthz", handler.Health)
	mux.HandleFunc("GET /api/v1/live-sessions/rooms", handler.ListSessions)
	mux.HandleFunc("POST /api/v1/live-sessions/rooms", handler.CreateRoom)
	mux.HandleFunc("DELETE /api/v1/live-sessions/rooms/{sessionId}", handler.DeleteSession)
	mux.HandleFunc("POST /api/v1/live-sessions/tokens", handler.CreateToken)
	mux.HandleFunc("GET /api/v1/live-sessions/{sessionId}/room", handler.GetRoom)
	mux.HandleFunc(
		"POST /api/v1/live-sessions/{sessionId}/attendance/sync",
		handler.SyncAttendance,
	)
	mux.HandleFunc(
		"PATCH /api/v1/live-sessions/{sessionId}/participants/{participantId}/media",
		handler.UpdateParticipantMedia,
	)
	mux.HandleFunc(
		"POST /api/v1/live-sessions/{sessionId}/chat/messages",
		handler.CreateChatMessage,
	)
	mux.HandleFunc(
		"POST /api/v1/live-sessions/{sessionId}/questions",
		handler.CreateQuestion,
	)
	mux.HandleFunc(
		"POST /api/v1/live-sessions/{sessionId}/questions/{questionId}/answer",
		handler.AnswerQuestion,
	)
	mux.HandleFunc(
		"POST /api/v1/live-sessions/{sessionId}/recordings",
		handler.UpdateRecording,
	)
	mux.HandleFunc(
		"POST /api/v1/live-sessions/{sessionId}/participants/{participantId}/audio/mute",
		handler.MuteParticipant,
	)
	mux.HandleFunc(
		"POST /api/v1/live-sessions/{sessionId}/participants/{participantId}/audio/unmute",
		handler.UnmuteParticipant,
	)

	return mux
}
