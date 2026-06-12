package api

import (
	"encoding/json"
	"errors"
	"net/http"

	"live_sessions_api/internal/service"
)

type Handler struct {
	service service.LiveSessionService
}

func NewHandler(svc service.LiveSessionService) *Handler {
	return &Handler{service: svc}
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) ListSessions(w http.ResponseWriter, r *http.Request) {
	res, err := h.service.ListSessions(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, res)
}

func (h *Handler) CreateRoom(w http.ResponseWriter, r *http.Request) {
	var req service.CreateRoomRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	res, err := h.service.CreateRoom(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, res)
}

func (h *Handler) DeleteSession(w http.ResponseWriter, r *http.Request) {
	if err := h.service.DeleteSession(r.Context(), r.PathValue("sessionId")); err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "deleted"})
}

func (h *Handler) CreateToken(w http.ResponseWriter, r *http.Request) {
	var req service.CreateTokenRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	res, err := h.service.CreateToken(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, res)
}

func (h *Handler) GetRoom(w http.ResponseWriter, r *http.Request) {
	res, err := h.service.GetRoom(r.Context(), r.PathValue("sessionId"))
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, res)
}

func (h *Handler) SyncAttendance(w http.ResponseWriter, r *http.Request) {
	var req service.SyncAttendanceRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	req.SessionID = r.PathValue("sessionId")
	res, err := h.service.SyncAttendance(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, res)
}

func (h *Handler) UpdateParticipantMedia(w http.ResponseWriter, r *http.Request) {
	var req service.UpdateParticipantMediaRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	req.SessionID = r.PathValue("sessionId")
	req.ParticipantID = r.PathValue("participantId")
	res, err := h.service.UpdateParticipantMedia(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, res)
}

func (h *Handler) CreateChatMessage(w http.ResponseWriter, r *http.Request) {
	var req service.CreateChatMessageRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	req.SessionID = r.PathValue("sessionId")
	res, err := h.service.CreateChatMessage(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, res)
}

func (h *Handler) CreateQuestion(w http.ResponseWriter, r *http.Request) {
	var req service.CreateQuestionRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	req.SessionID = r.PathValue("sessionId")
	res, err := h.service.CreateQuestion(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, res)
}

func (h *Handler) AnswerQuestion(w http.ResponseWriter, r *http.Request) {
	var req service.AnswerQuestionRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	req.SessionID = r.PathValue("sessionId")
	req.QuestionID = r.PathValue("questionId")
	res, err := h.service.AnswerQuestion(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, res)
}

func (h *Handler) UpdateRecording(w http.ResponseWriter, r *http.Request) {
	var req service.UpdateRecordingRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	req.SessionID = r.PathValue("sessionId")
	res, err := h.service.UpdateRecording(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, res)
}

func (h *Handler) MuteParticipant(w http.ResponseWriter, r *http.Request) {
	req := service.ModerationCommandRequest{
		SessionID:     r.PathValue("sessionId"),
		ParticipantID: r.PathValue("participantId"),
		Action:        service.ModerationActionMute,
	}
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	req.SessionID = r.PathValue("sessionId")
	req.ParticipantID = r.PathValue("participantId")
	res, err := h.service.ModerateParticipantAudio(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, res)
}

func (h *Handler) UnmuteParticipant(w http.ResponseWriter, r *http.Request) {
	req := service.ModerationCommandRequest{
		SessionID:     r.PathValue("sessionId"),
		ParticipantID: r.PathValue("participantId"),
		Action:        service.ModerationActionUnmute,
	}
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, err)
		return
	}
	req.SessionID = r.PathValue("sessionId")
	req.ParticipantID = r.PathValue("participantId")
	res, err := h.service.ModerateParticipantAudio(r.Context(), req)
	if err != nil {
		writeError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, res)
}

func decodeJSON(r *http.Request, target any) error {
	defer r.Body.Close()
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	return nil
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, err error) {
	status := http.StatusBadRequest
	switch {
	case errors.Is(err, service.ErrNotFound):
		status = http.StatusNotFound
	case errors.Is(err, service.ErrConflict):
		status = http.StatusConflict
	case errors.Is(err, service.ErrValidation):
		status = http.StatusUnprocessableEntity
	}
	writeJSON(w, status, map[string]string{"error": err.Error()})
}
