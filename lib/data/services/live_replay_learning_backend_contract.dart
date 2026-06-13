import '../models/live_session_models.dart';

class LiveReplayLearningBackendContract {
  const LiveReplayLearningBackendContract._();

  static const List<LiveSessionBackendPath> paths = [
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/{sessionId}/replay-learning/bookmarks',
      description:
          'Return a student replay-learning bookmark list for one recorded live class.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/replay-learning/bookmarks/sync',
      description:
          'Sync local replay bookmarks and important moments from the student device to the backend.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/live-sessions/{sessionId}/replay-learning/questions/generate',
      description:
          'Generate quick revision questions from replay transcript, agenda, materials, saved notes, and important moments.',
    ),
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/live-sessions/{sessionId}/replay-learning/questions',
      description:
          'Return saved or generated quick revision questions for a replay session.',
    ),
  ];

  static Map<String, dynamic> bookmarkSyncPayloadExample() => {
    'sessionId': 'live-csc305-replay',
    'bookmarks': [
      {
        'bookmarkId': 'uuid-value',
        'sessionId': 'live-csc305-replay',
        'minute': 24,
        'title': 'Important lecturer explanation',
        'note': 'Return here before exam revision.',
        'important': true,
        'createdAt': '2026-06-13T10:00:00Z',
      },
    ],
    'syncedAt': '2026-06-13T10:05:00Z',
  };

  static Map<String, dynamic> questionGenerationPayloadExample() => {
    'sessionId': 'live-csc305-replay',
    'studentId': 'student-registration-number',
    'source': {
      'agenda': ['Heap insertion and deletion drills'],
      'notes': 'Student saved notes from replay',
      'importantBookmarks': [
        {
          'minute': 24,
          'title': 'Important lecturer explanation',
          'note': 'Return here before exam revision.',
        },
      ],
    },
  };
}
