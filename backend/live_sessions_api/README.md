# Live Sessions Go API

This module is the backend contract scaffold for the live-session feature.

The lecturer portal is separate from the Flutter app, but both clients use the
same backend:

- Lecturer portal: creates rooms, answers questions, starts/stops lecturer
  recordings, and mutes/unmutes students
- Student app: requests tokens, joins rooms, syncs attendance, updates mic/camera
  state, sends chat messages, asks questions, and can start/stop student-side
  recordings if the room allows it

## API shape

Base path: `/api/v1/live-sessions`

### Lecturer portal

- `POST /api/v1/live-sessions/rooms`
- `GET /api/v1/live-sessions/{sessionId}/room`
- `POST /api/v1/live-sessions/{sessionId}/questions/{questionId}/answer`
- `POST /api/v1/live-sessions/{sessionId}/recordings`
- `POST /api/v1/live-sessions/{sessionId}/participants/{participantId}/audio/mute`
- `POST /api/v1/live-sessions/{sessionId}/participants/{participantId}/audio/unmute`

### Student app

- `POST /api/v1/live-sessions/tokens`
- `GET /api/v1/live-sessions/{sessionId}/room`
- `POST /api/v1/live-sessions/{sessionId}/attendance/sync`
- `PATCH /api/v1/live-sessions/{sessionId}/participants/{participantId}/media`
- `POST /api/v1/live-sessions/{sessionId}/chat/messages`
- `POST /api/v1/live-sessions/{sessionId}/questions`
- `POST /api/v1/live-sessions/{sessionId}/recordings`

### Realtime

- `WS /ws/v1/live-sessions/{sessionId}`

Use the WebSocket path for room presence, chat fan-out, question updates, mute
events, and attendance refresh. Use LiveKit/WebRTC for media transport and use
these REST routes for room control and persistence.

## Notes

- `cmd/server/main.go` wires the HTTP server.
- `internal/api/router.go` declares the exact route map.
- `internal/api/handlers.go` handles JSON input/output and path params.
- `internal/service/live_sessions.go` contains the request/response models and a
  simple in-memory service scaffold.

## Replace before production

- Replace the placeholder token issuer with real LiveKit token generation.
- Persist room state, chat, attendance, questions, and recordings in a database.
- Back recording actions with LiveKit egress or another recording pipeline.
- Back mute/unmute with your chosen media server moderation APIs.
