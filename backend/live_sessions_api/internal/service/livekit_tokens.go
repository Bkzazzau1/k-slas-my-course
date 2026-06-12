package service

import (
	"strings"
	"time"

	"github.com/livekit/protocol/auth"
)

const defaultLiveKitTokenTTL = 2 * time.Hour

type TokenIssuer interface {
	IssueToken(roomName, participantIdentity string) (string, error)
	ExpiresAt(now time.Time) time.Time
}

type LiveKitTokenIssuer struct {
	apiKey    string
	apiSecret string
	ttl       time.Duration
}

func NewLiveKitTokenIssuer(apiKey, apiSecret string) *LiveKitTokenIssuer {
	return &LiveKitTokenIssuer{
		apiKey:    strings.TrimSpace(apiKey),
		apiSecret: strings.TrimSpace(apiSecret),
		ttl:       defaultLiveKitTokenTTL,
	}
}

func (i *LiveKitTokenIssuer) IssueToken(roomName, participantIdentity string) (string, error) {
	if i == nil || i.apiKey == "" || i.apiSecret == "" {
		return "", validationError("LIVEKIT_API_KEY and LIVEKIT_API_SECRET must be configured")
	}
	if strings.TrimSpace(roomName) == "" || strings.TrimSpace(participantIdentity) == "" {
		return "", validationError("roomName and participantIdentity are required")
	}

	token := auth.NewAccessToken(i.apiKey, i.apiSecret).
		AddGrant(&auth.VideoGrant{
			RoomJoin: true,
			Room:     strings.TrimSpace(roomName),
		}).
		SetIdentity(strings.TrimSpace(participantIdentity)).
		SetValidFor(i.ttl)

	accessToken, err := token.ToJWT()
	if err != nil {
		return "", conflictError("unable to issue LiveKit access token")
	}
	return accessToken, nil
}

func (i *LiveKitTokenIssuer) ExpiresAt(now time.Time) time.Time {
	if i == nil || i.ttl <= 0 {
		return now.UTC().Add(defaultLiveKitTokenTTL)
	}
	return now.UTC().Add(i.ttl)
}
