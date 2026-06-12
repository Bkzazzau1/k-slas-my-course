package service

import (
	"context"
	"errors"
	"fmt"
	"os"
	"sort"
	"strings"
	"sync"
	"time"
)

var (
	ErrNotFound   = errors.New("not found")
	ErrConflict   = errors.New("conflict")
	ErrValidation = errors.New("validation failed")
)

const (
	RoleLecturer = "lecturer"
	RoleStudent  = "student"

	ModerationActionMute   = "mute"
	ModerationActionUnmute = "unmute"

	RecordingActionStart = "start"
	RecordingActionStop  = "stop"
)

type Material struct {
	Title    string `json:"title"`
	Subtitle string `json:"subtitle"`
	Status   string `json:"status"`
}

type RoomSettings struct {
	StudentCameraRequired     bool `json:"studentCameraRequired"`
	CaptureRegistrationNumber bool `json:"captureRegistrationNumber"`
	AllowStudentRecording     bool `json:"allowStudentRecording"`
	AllowLecturerRecording    bool `json:"allowLecturerRecording"`
	AttendanceEnabled         bool `json:"attendanceEnabled"`
	ChatEnabled               bool `json:"chatEnabled"`
	QuestionsEnabled          bool `json:"questionsEnabled"`
}

type SessionInfo struct {
	SessionID    string       `json:"sessionId"`
	CourseCode   string       `json:"courseCode"`
	CourseTitle  string       `json:"courseTitle"`
	Title        string       `json:"title"`
	Description  string       `json:"description"`
	LecturerID   string       `json:"lecturerId"`
	LecturerName string       `json:"lecturerName"`
	RoomName     string       `json:"roomName"`
	StartTime    time.Time    `json:"startTime"`
	EndTime      time.Time    `json:"endTime"`
	Agenda       []string     `json:"agenda"`
	Materials    []Material   `json:"materials"`
	Settings     RoomSettings `json:"settings"`
}

type ParticipantState struct {
	ParticipantID      string     `json:"participantId"`
	UserID             string     `json:"userId"`
	Role               string     `json:"role"`
	DisplayName        string     `json:"displayName"`
	RegistrationNumber string     `json:"registrationNumber,omitempty"`
	CameraEnabled      bool       `json:"cameraEnabled"`
	MicEnabled         bool       `json:"micEnabled"`
	MutedByLecturer    bool       `json:"mutedByLecturer"`
	RecordingEnabled   bool       `json:"recordingEnabled"`
	AttendanceSeconds  int64      `json:"attendanceSeconds"`
	JoinedAt           *time.Time `json:"joinedAt,omitempty"`
	LeftAt             *time.Time `json:"leftAt,omitempty"`
	UpdatedAt          time.Time  `json:"updatedAt"`
}

type ChatMessage struct {
	MessageID          string    `json:"messageId"`
	SessionID          string    `json:"sessionId"`
	SenderParticipantID string   `json:"senderParticipantId"`
	SenderRole         string    `json:"senderRole"`
	SenderName         string    `json:"senderName"`
	RegistrationNumber string    `json:"registrationNumber,omitempty"`
	Message            string    `json:"message"`
	SentAt             time.Time `json:"sentAt"`
}

type Question struct {
	QuestionID          string     `json:"questionId"`
	SessionID           string     `json:"sessionId"`
	AskedByParticipantID string    `json:"askedByParticipantId"`
	AskedByName         string     `json:"askedByName"`
	RegistrationNumber  string     `json:"registrationNumber,omitempty"`
	Question            string     `json:"question"`
	AskedAt             time.Time  `json:"askedAt"`
	Answer              string     `json:"answer,omitempty"`
	AnsweredByID        string     `json:"answeredById,omitempty"`
	AnsweredByName      string     `json:"answeredByName,omitempty"`
	AnsweredAt          *time.Time `json:"answeredAt,omitempty"`
}

type Recording struct {
	RecordingID         string     `json:"recordingId"`
	SessionID           string     `json:"sessionId"`
	TriggeredByParticipantID string `json:"triggeredByParticipantId"`
	TriggeredByRole     string     `json:"triggeredByRole"`
	TriggeredByName     string     `json:"triggeredByName"`
	RegistrationNumber  string     `json:"registrationNumber,omitempty"`
	Action              string     `json:"action"`
	Active              bool       `json:"active"`
	StartedAt           time.Time  `json:"startedAt"`
	StoppedAt           *time.Time `json:"stoppedAt,omitempty"`
}

type LiveSessionRoomState struct {
	Session      SessionInfo        `json:"session"`
	Participants []ParticipantState `json:"participants"`
	ChatMessages []ChatMessage      `json:"chatMessages"`
	Questions    []Question         `json:"questions"`
	Recordings   []Recording        `json:"recordings"`
}

type CreateRoomRequest struct {
	SessionID    string     `json:"sessionId"`
	CourseCode   string     `json:"courseCode"`
	CourseTitle  string     `json:"courseTitle"`
	Title        string     `json:"title"`
	Description  string     `json:"description"`
	LecturerID   string     `json:"lecturerId"`
	LecturerName string     `json:"lecturerName"`
	RoomName     string     `json:"roomName"`
	StartTime    time.Time  `json:"startTime"`
	EndTime      time.Time  `json:"endTime"`
	Agenda       []string   `json:"agenda"`
	Materials    []Material `json:"materials"`
	Settings     RoomSettings `json:"settings"`
}

type CreateRoomResponse struct {
	Session           SessionInfo `json:"session"`
	TokenEndpoint     string      `json:"tokenEndpoint"`
	RoomStateEndpoint string      `json:"roomStateEndpoint"`
	SocketEndpoint    string      `json:"socketEndpoint"`
}

type ListSessionsResponse struct {
	Sessions []SessionInfo `json:"sessions"`
}

type CreateTokenRequest struct {
	SessionID          string `json:"sessionId"`
	ParticipantID      string `json:"participantId,omitempty"`
	UserID             string `json:"userId"`
	Role               string `json:"role"`
	DisplayName        string `json:"displayName"`
	RegistrationNumber string `json:"registrationNumber,omitempty"`
}

type CreateTokenResponse struct {
	SessionID           string    `json:"sessionId"`
	ParticipantID       string    `json:"participantId"`
	ParticipantIdentity string    `json:"participantIdentity"`
	Role                string    `json:"role"`
	RoomName            string    `json:"roomName"`
	AccessToken         string    `json:"accessToken"`
	CanPublishAudio     bool      `json:"canPublishAudio"`
	CanPublishVideo     bool      `json:"canPublishVideo"`
	CanSubscribe        bool      `json:"canSubscribe"`
	ExpiresAt           time.Time `json:"expiresAt"`
}

type SyncAttendanceRequest struct {
	SessionID          string     `json:"sessionId"`
	ParticipantID      string     `json:"participantId"`
	UserID             string     `json:"userId"`
	Role               string     `json:"role"`
	DisplayName        string     `json:"displayName"`
	RegistrationNumber string     `json:"registrationNumber,omitempty"`
	CameraEnabled      bool       `json:"cameraEnabled"`
	MicEnabled         bool       `json:"micEnabled"`
	RecordingEnabled   bool       `json:"recordingEnabled"`
	AttendanceSeconds  int64      `json:"attendanceSeconds"`
	JoinedAt           *time.Time `json:"joinedAt,omitempty"`
	LeftAt             *time.Time `json:"leftAt,omitempty"`
	UpdatedAt          time.Time  `json:"updatedAt"`
}

type UpdateParticipantMediaRequest struct {
	SessionID        string    `json:"sessionId"`
	ParticipantID    string    `json:"participantId"`
	CameraEnabled    bool      `json:"cameraEnabled"`
	MicEnabled       bool      `json:"micEnabled"`
	RecordingEnabled bool      `json:"recordingEnabled"`
	UpdatedAt        time.Time `json:"updatedAt"`
}

type CreateChatMessageRequest struct {
	SessionID           string    `json:"sessionId"`
	SenderParticipantID string    `json:"senderParticipantId"`
	SenderRole          string    `json:"senderRole"`
	SenderName          string    `json:"senderName"`
	RegistrationNumber  string    `json:"registrationNumber,omitempty"`
	Message             string    `json:"message"`
	SentAt              time.Time `json:"sentAt"`
}

type CreateQuestionRequest struct {
	SessionID           string    `json:"sessionId"`
	AskedByParticipantID string   `json:"askedByParticipantId"`
	AskedByName         string    `json:"askedByName"`
	RegistrationNumber  string    `json:"registrationNumber,omitempty"`
	Question            string    `json:"question"`
	AskedAt             time.Time `json:"askedAt"`
}

type AnswerQuestionRequest struct {
	SessionID      string    `json:"sessionId"`
	QuestionID     string    `json:"questionId"`
	AnsweredByID   string    `json:"answeredById"`
	AnsweredByName string    `json:"answeredByName"`
	Answer         string    `json:"answer"`
	AnsweredAt     time.Time `json:"answeredAt"`
}

type UpdateRecordingRequest struct {
	SessionID              string    `json:"sessionId"`
	RecordingID            string    `json:"recordingId,omitempty"`
	TriggeredByParticipantID string  `json:"triggeredByParticipantId"`
	TriggeredByRole        string    `json:"triggeredByRole"`
	TriggeredByName        string    `json:"triggeredByName"`
	RegistrationNumber     string    `json:"registrationNumber,omitempty"`
	Action                 string    `json:"action"`
	RequestedAt            time.Time `json:"requestedAt"`
}

type ModerationCommandRequest struct {
	SessionID     string    `json:"sessionId"`
	ParticipantID string    `json:"participantId"`
	LecturerID    string    `json:"lecturerId"`
	LecturerName  string    `json:"lecturerName"`
	Action        string    `json:"action"`
	RequestedAt   time.Time `json:"requestedAt"`
}

type LiveSessionService interface {
	ListSessions(context.Context) (ListSessionsResponse, error)
	CreateRoom(context.Context, CreateRoomRequest) (CreateRoomResponse, error)
	DeleteSession(context.Context, string) error
	CreateToken(context.Context, CreateTokenRequest) (CreateTokenResponse, error)
	GetRoom(context.Context, string) (LiveSessionRoomState, error)
	SyncAttendance(context.Context, SyncAttendanceRequest) (ParticipantState, error)
	UpdateParticipantMedia(context.Context, UpdateParticipantMediaRequest) (ParticipantState, error)
	CreateChatMessage(context.Context, CreateChatMessageRequest) (ChatMessage, error)
	CreateQuestion(context.Context, CreateQuestionRequest) (Question, error)
	AnswerQuestion(context.Context, AnswerQuestionRequest) (Question, error)
	UpdateRecording(context.Context, UpdateRecordingRequest) (Recording, error)
	ModerateParticipantAudio(context.Context, ModerationCommandRequest) (ParticipantState, error)
}

type ContractService struct {
	mu          sync.RWMutex
	rooms       map[string]*LiveSessionRoomState
	tokenIssuer TokenIssuer
}

func NewContractService() *ContractService {
	return &ContractService{
		rooms:       make(map[string]*LiveSessionRoomState),
		tokenIssuer: NewLiveKitTokenIssuer(os.Getenv("LIVEKIT_API_KEY"), os.Getenv("LIVEKIT_API_SECRET")),
	}
}

func (s *ContractService) ListSessions(_ context.Context) (ListSessionsResponse, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	sessions := make([]SessionInfo, 0, len(s.rooms))
	for _, room := range s.rooms {
		sessions = append(sessions, cloneSession(room.Session))
	}

	sort.Slice(sessions, func(i, j int) bool {
		return sessions[i].StartTime.Before(sessions[j].StartTime)
	})

	return ListSessionsResponse{Sessions: sessions}, nil
}

func (s *ContractService) CreateRoom(_ context.Context, req CreateRoomRequest) (CreateRoomResponse, error) {
	if err := validateCreateRoom(req); err != nil {
		return CreateRoomResponse{}, err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	state, ok := s.rooms[req.SessionID]
	if !ok {
		state = &LiveSessionRoomState{}
		s.rooms[req.SessionID] = state
	}
	state.Session = SessionInfo{
		SessionID:    req.SessionID,
		CourseCode:   strings.TrimSpace(req.CourseCode),
		CourseTitle:  strings.TrimSpace(req.CourseTitle),
		Title:        strings.TrimSpace(req.Title),
		Description:  strings.TrimSpace(req.Description),
		LecturerID:   strings.TrimSpace(req.LecturerID),
		LecturerName: strings.TrimSpace(req.LecturerName),
		RoomName:     strings.TrimSpace(req.RoomName),
		StartTime:    req.StartTime,
		EndTime:      req.EndTime,
		Agenda:       append([]string(nil), req.Agenda...),
		Materials:    append([]Material(nil), req.Materials...),
		Settings:     req.Settings,
	}

	return CreateRoomResponse{
		Session:           state.Session,
		TokenEndpoint:     "/api/v1/live-sessions/tokens",
		RoomStateEndpoint: fmt.Sprintf("/api/v1/live-sessions/%s/room", req.SessionID),
		SocketEndpoint:    fmt.Sprintf("/ws/v1/live-sessions/%s", req.SessionID),
	}, nil
}

func (s *ContractService) DeleteSession(_ context.Context, sessionID string) error {
	if strings.TrimSpace(sessionID) == "" {
		return validationError("sessionId is required")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if _, ok := s.rooms[sessionID]; !ok {
		return notFoundError("session room not found")
	}

	delete(s.rooms, sessionID)
	return nil
}

func (s *ContractService) CreateToken(_ context.Context, req CreateTokenRequest) (CreateTokenResponse, error) {
	if err := validateRole(req.Role); err != nil {
		return CreateTokenResponse{}, err
	}
	if strings.TrimSpace(req.SessionID) == "" || strings.TrimSpace(req.UserID) == "" || strings.TrimSpace(req.DisplayName) == "" {
		return CreateTokenResponse{}, validationError("sessionId, userId, and displayName are required")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	room, ok := s.rooms[req.SessionID]
	if !ok {
		return CreateTokenResponse{}, notFoundError("session room not found")
	}

	participantID := strings.TrimSpace(req.ParticipantID)
	if participantID == "" {
		participantID = buildParticipantID(req.Role, req.UserID, req.RegistrationNumber)
	}

	now := time.Now().UTC()
	participant := upsertParticipant(room, ParticipantState{
		ParticipantID:      participantID,
		UserID:             strings.TrimSpace(req.UserID),
		Role:               req.Role,
		DisplayName:        strings.TrimSpace(req.DisplayName),
		RegistrationNumber: strings.TrimSpace(req.RegistrationNumber),
		CameraEnabled:      req.Role == RoleLecturer || room.Session.Settings.StudentCameraRequired,
		MicEnabled:         true,
		RecordingEnabled:   false,
		UpdatedAt:          now,
	})
	accessToken, err := s.tokenIssuer.IssueToken(room.Session.RoomName, participant.ParticipantID)
	if err != nil {
		return CreateTokenResponse{}, err
	}

	return CreateTokenResponse{
		SessionID:           room.Session.SessionID,
		ParticipantID:       participant.ParticipantID,
		ParticipantIdentity: participant.ParticipantID,
		Role:                participant.Role,
		RoomName:            room.Session.RoomName,
		AccessToken:         accessToken,
		CanPublishAudio:     true,
		CanPublishVideo:     true,
		CanSubscribe:        true,
		ExpiresAt:           s.tokenIssuer.ExpiresAt(now),
	}, nil
}

func (s *ContractService) GetRoom(_ context.Context, sessionID string) (LiveSessionRoomState, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	room, ok := s.rooms[sessionID]
	if !ok {
		return LiveSessionRoomState{}, notFoundError("session room not found")
	}
	return cloneRoom(*room), nil
}

func (s *ContractService) SyncAttendance(_ context.Context, req SyncAttendanceRequest) (ParticipantState, error) {
	if strings.TrimSpace(req.SessionID) == "" || strings.TrimSpace(req.ParticipantID) == "" {
		return ParticipantState{}, validationError("sessionId and participantId are required")
	}
	if err := validateRole(req.Role); err != nil {
		return ParticipantState{}, err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	room, ok := s.rooms[req.SessionID]
	if !ok {
		return ParticipantState{}, notFoundError("session room not found")
	}

	updatedAt := req.UpdatedAt
	if updatedAt.IsZero() {
		updatedAt = time.Now().UTC()
	}

	participant := upsertParticipant(room, ParticipantState{
		ParticipantID:      req.ParticipantID,
		UserID:             strings.TrimSpace(req.UserID),
		Role:               req.Role,
		DisplayName:        strings.TrimSpace(req.DisplayName),
		RegistrationNumber: strings.TrimSpace(req.RegistrationNumber),
		CameraEnabled:      req.CameraEnabled,
		MicEnabled:         req.MicEnabled,
		RecordingEnabled:   req.RecordingEnabled,
		AttendanceSeconds:  req.AttendanceSeconds,
		JoinedAt:           req.JoinedAt,
		LeftAt:             req.LeftAt,
		UpdatedAt:          updatedAt,
	})

	return participant, nil
}

func (s *ContractService) UpdateParticipantMedia(_ context.Context, req UpdateParticipantMediaRequest) (ParticipantState, error) {
	if strings.TrimSpace(req.SessionID) == "" || strings.TrimSpace(req.ParticipantID) == "" {
		return ParticipantState{}, validationError("sessionId and participantId are required")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	room, ok := s.rooms[req.SessionID]
	if !ok {
		return ParticipantState{}, notFoundError("session room not found")
	}

	index := findParticipantIndex(room.Participants, req.ParticipantID)
	if index < 0 {
		return ParticipantState{}, notFoundError("participant not found")
	}

	participant := room.Participants[index]
	participant.CameraEnabled = req.CameraEnabled
	if participant.MutedByLecturer && req.MicEnabled {
		participant.MicEnabled = false
	} else {
		participant.MicEnabled = req.MicEnabled
	}
	participant.RecordingEnabled = req.RecordingEnabled
	participant.UpdatedAt = timestampOrNow(req.UpdatedAt)
	room.Participants[index] = participant

	return participant, nil
}

func (s *ContractService) CreateChatMessage(_ context.Context, req CreateChatMessageRequest) (ChatMessage, error) {
	if strings.TrimSpace(req.SessionID) == "" || strings.TrimSpace(req.Message) == "" {
		return ChatMessage{}, validationError("sessionId and message are required")
	}
	if err := validateRole(req.SenderRole); err != nil {
		return ChatMessage{}, err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	room, ok := s.rooms[req.SessionID]
	if !ok {
		return ChatMessage{}, notFoundError("session room not found")
	}

	message := ChatMessage{
		MessageID:           buildID("msg", time.Now().UTC()),
		SessionID:           req.SessionID,
		SenderParticipantID: strings.TrimSpace(req.SenderParticipantID),
		SenderRole:          req.SenderRole,
		SenderName:          strings.TrimSpace(req.SenderName),
		RegistrationNumber:  strings.TrimSpace(req.RegistrationNumber),
		Message:             strings.TrimSpace(req.Message),
		SentAt:              timestampOrNow(req.SentAt),
	}
	room.ChatMessages = append(room.ChatMessages, message)
	return message, nil
}

func (s *ContractService) CreateQuestion(_ context.Context, req CreateQuestionRequest) (Question, error) {
	if strings.TrimSpace(req.SessionID) == "" || strings.TrimSpace(req.Question) == "" {
		return Question{}, validationError("sessionId and question are required")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	room, ok := s.rooms[req.SessionID]
	if !ok {
		return Question{}, notFoundError("session room not found")
	}

	question := Question{
		QuestionID:           buildID("q", time.Now().UTC()),
		SessionID:            req.SessionID,
		AskedByParticipantID: strings.TrimSpace(req.AskedByParticipantID),
		AskedByName:          strings.TrimSpace(req.AskedByName),
		RegistrationNumber:   strings.TrimSpace(req.RegistrationNumber),
		Question:             strings.TrimSpace(req.Question),
		AskedAt:              timestampOrNow(req.AskedAt),
	}
	room.Questions = append(room.Questions, question)
	return question, nil
}

func (s *ContractService) AnswerQuestion(_ context.Context, req AnswerQuestionRequest) (Question, error) {
	if strings.TrimSpace(req.SessionID) == "" || strings.TrimSpace(req.QuestionID) == "" || strings.TrimSpace(req.Answer) == "" {
		return Question{}, validationError("sessionId, questionId, and answer are required")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	room, ok := s.rooms[req.SessionID]
	if !ok {
		return Question{}, notFoundError("session room not found")
	}

	for index, item := range room.Questions {
		if item.QuestionID != req.QuestionID {
			continue
		}
		answerTime := timestampOrNow(req.AnsweredAt)
		item.Answer = strings.TrimSpace(req.Answer)
		item.AnsweredByID = strings.TrimSpace(req.AnsweredByID)
		item.AnsweredByName = strings.TrimSpace(req.AnsweredByName)
		item.AnsweredAt = &answerTime
		room.Questions[index] = item
		return item, nil
	}

	return Question{}, notFoundError("question not found")
}

func (s *ContractService) UpdateRecording(_ context.Context, req UpdateRecordingRequest) (Recording, error) {
	if strings.TrimSpace(req.SessionID) == "" || strings.TrimSpace(req.Action) == "" {
		return Recording{}, validationError("sessionId and action are required")
	}
	if req.Action != RecordingActionStart && req.Action != RecordingActionStop {
		return Recording{}, validationError("recording action must be start or stop")
	}
	if err := validateRole(req.TriggeredByRole); err != nil {
		return Recording{}, err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	room, ok := s.rooms[req.SessionID]
	if !ok {
		return Recording{}, notFoundError("session room not found")
	}

	requestedAt := timestampOrNow(req.RequestedAt)
	if req.Action == RecordingActionStart {
		recording := Recording{
			RecordingID:             buildID("rec", requestedAt),
			SessionID:               req.SessionID,
			TriggeredByParticipantID: strings.TrimSpace(req.TriggeredByParticipantID),
			TriggeredByRole:         req.TriggeredByRole,
			TriggeredByName:         strings.TrimSpace(req.TriggeredByName),
			RegistrationNumber:      strings.TrimSpace(req.RegistrationNumber),
			Action:                  RecordingActionStart,
			Active:                  true,
			StartedAt:               requestedAt,
		}
		room.Recordings = append(room.Recordings, recording)
		return recording, nil
	}

	for index := len(room.Recordings) - 1; index >= 0; index-- {
		item := room.Recordings[index]
		if req.RecordingID != "" && item.RecordingID != req.RecordingID {
			continue
		}
		if item.Active {
			item.Active = false
			item.Action = RecordingActionStop
			item.StoppedAt = &requestedAt
			room.Recordings[index] = item
			return item, nil
		}
	}

	return Recording{}, notFoundError("active recording not found")
}

func (s *ContractService) ModerateParticipantAudio(_ context.Context, req ModerationCommandRequest) (ParticipantState, error) {
	if strings.TrimSpace(req.SessionID) == "" || strings.TrimSpace(req.ParticipantID) == "" {
		return ParticipantState{}, validationError("sessionId and participantId are required")
	}
	if req.Action != ModerationActionMute && req.Action != ModerationActionUnmute {
		return ParticipantState{}, validationError("moderation action must be mute or unmute")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	room, ok := s.rooms[req.SessionID]
	if !ok {
		return ParticipantState{}, notFoundError("session room not found")
	}

	index := findParticipantIndex(room.Participants, req.ParticipantID)
	if index < 0 {
		return ParticipantState{}, notFoundError("participant not found")
	}

	participant := room.Participants[index]
	if participant.Role != RoleStudent {
		return ParticipantState{}, conflictError("only student participants can be muted or unmuted")
	}

	participant.MutedByLecturer = req.Action == ModerationActionMute
	participant.MicEnabled = req.Action != ModerationActionMute
	participant.UpdatedAt = timestampOrNow(req.RequestedAt)
	room.Participants[index] = participant

	return participant, nil
}

func validateCreateRoom(req CreateRoomRequest) error {
	if strings.TrimSpace(req.SessionID) == "" ||
		strings.TrimSpace(req.CourseCode) == "" ||
		strings.TrimSpace(req.Title) == "" ||
		strings.TrimSpace(req.LecturerID) == "" ||
		strings.TrimSpace(req.LecturerName) == "" ||
		strings.TrimSpace(req.RoomName) == "" {
		return validationError("sessionId, courseCode, title, lecturerId, lecturerName, and roomName are required")
	}
	if req.EndTime.Before(req.StartTime) || req.EndTime.Equal(req.StartTime) {
		return validationError("endTime must be after startTime")
	}
	return nil
}

func validateRole(role string) error {
	switch role {
	case RoleLecturer, RoleStudent:
		return nil
	default:
		return validationError("role must be lecturer or student")
	}
}

func upsertParticipant(room *LiveSessionRoomState, incoming ParticipantState) ParticipantState {
	index := findParticipantIndex(room.Participants, incoming.ParticipantID)
	if index >= 0 {
		existing := room.Participants[index]
		existing.UserID = nonEmpty(incoming.UserID, existing.UserID)
		existing.Role = nonEmpty(incoming.Role, existing.Role)
		existing.DisplayName = nonEmpty(incoming.DisplayName, existing.DisplayName)
		existing.RegistrationNumber = nonEmpty(incoming.RegistrationNumber, existing.RegistrationNumber)
		existing.CameraEnabled = incoming.CameraEnabled
		existing.MicEnabled = incoming.MicEnabled
		existing.RecordingEnabled = incoming.RecordingEnabled
		existing.AttendanceSeconds = incoming.AttendanceSeconds
		existing.JoinedAt = chooseTime(incoming.JoinedAt, existing.JoinedAt)
		existing.LeftAt = chooseTime(incoming.LeftAt, existing.LeftAt)
		existing.UpdatedAt = timestampOrNow(incoming.UpdatedAt)
		room.Participants[index] = existing
		return existing
	}

	incoming.UpdatedAt = timestampOrNow(incoming.UpdatedAt)
	room.Participants = append(room.Participants, incoming)
	return incoming
}

func findParticipantIndex(items []ParticipantState, participantID string) int {
	for index, item := range items {
		if item.ParticipantID == participantID {
			return index
		}
	}
	return -1
}

func cloneRoom(room LiveSessionRoomState) LiveSessionRoomState {
	room.Participants = append([]ParticipantState(nil), room.Participants...)
	room.ChatMessages = append([]ChatMessage(nil), room.ChatMessages...)
	room.Questions = append([]Question(nil), room.Questions...)
	room.Recordings = append([]Recording(nil), room.Recordings...)
	room.Session = cloneSession(room.Session)
	return room
}

func cloneSession(session SessionInfo) SessionInfo {
	session.Agenda = append([]string(nil), session.Agenda...)
	session.Materials = append([]Material(nil), session.Materials...)
	return session
}

func buildParticipantID(role, userID, registrationNumber string) string {
	key := strings.TrimSpace(userID)
	if strings.TrimSpace(registrationNumber) != "" {
		key = registrationNumber
	}
	key = strings.ToLower(strings.ReplaceAll(strings.TrimSpace(key), " ", "-"))
	return fmt.Sprintf("%s-%s", role, key)
}

func issuePlaceholderToken(sessionID, participantID string) string {
	return fmt.Sprintf("replace-with-livekit-token:%s:%s", sessionID, participantID)
}

func buildID(prefix string, value time.Time) string {
	return fmt.Sprintf("%s-%d", prefix, value.UnixNano())
}

func timestampOrNow(value time.Time) time.Time {
	if value.IsZero() {
		return time.Now().UTC()
	}
	return value.UTC()
}

func chooseTime(next, current *time.Time) *time.Time {
	if next != nil {
		return next
	}
	return current
}

func nonEmpty(next, current string) string {
	if strings.TrimSpace(next) != "" {
		return strings.TrimSpace(next)
	}
	return current
}

func validationError(message string) error {
	return fmt.Errorf("%w: %s", ErrValidation, message)
}

func notFoundError(message string) error {
	return fmt.Errorf("%w: %s", ErrNotFound, message)
}

func conflictError(message string) error {
	return fmt.Errorf("%w: %s", ErrConflict, message)
}
