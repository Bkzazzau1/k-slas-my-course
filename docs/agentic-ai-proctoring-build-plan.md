# K-SLAS Agentic AI Proctoring Build Plan

## 1. Purpose

This document defines the build plan for adding Agentic AI Proctoring into K-SLAS. The goal is to create a low-cost, scalable, fair, and evidence-based proctoring system for university examinations and graded assessments.

The system must support:

- High-stakes examinations
- Graded assessments
- Distance learning students
- CBT centre students
- Invigilator monitoring
- Exam officer review
- HoD / Chief Exam Officer approval
- Academic Records final documentation
- Future proprietary AI model training

The system must not automatically punish students. It should detect suspicious activity, record evidence, assign risk levels, and send cases to authorized human reviewers.

---

## 2. Device Policy

### 2.1 High-Stakes Examinations

High-stakes examinations should be supported on:

- Desktop computer
- Laptop
- Tablet
- iPad

Mobile phones should not be the default device for final examinations unless the university grants special approval.

### 2.2 Graded Assessments

Graded assessments may be supported on:

- Mobile phone
- Tablet
- iPad
- Laptop
- Desktop computer

Graded assessments are usually shorter and lower-risk than final examinations, so mobile access can be allowed with light or medium proctoring.

### 2.3 Device-Based Proctoring Strength

| Device | Final Exam | Graded Assessment | Proctoring Strength |
|---|---|---|---|
| Desktop/Laptop | Allowed | Allowed | Full proctoring |
| Tablet/iPad | Allowed | Allowed | Strong proctoring |
| Mobile phone | Restricted / special approval | Allowed | Light or medium proctoring |

---

## 3. Core Architecture Principle

## Local-first AI, cloud-only-when-needed

The system should not send live video, live audio, or continuous screen recordings of every student to cloud AI.

### Local AI should handle:

- Face detection
- Multiple-face detection
- Student absent from camera
- Looking-away detection
- Phone/object detection
- Human voice detection
- Fan/generator/car/background noise recognition
- Tab switching
- Copy/paste detection
- External app detection
- Remote desktop detection
- Risk score calculation
- Event logging

### Cloud AI should handle only:

- Suspicious incident explanation
- Human-readable misconduct report
- Serious case review support
- Appeal-support summary
- Final audit report generation

This design keeps AI cost low and protects student privacy.

---

## 4. Main System Components

### 4.1 Student Exam App

The student exam app is used for examinations and assessments.

Required features:

- Student login
- Exam list
- Device readiness check
- Camera check
- Microphone check
- Face verification
- Exam rules acceptance
- Secure exam interface
- Full-screen exam mode where supported
- Screen/app monitoring where supported
- Copy/paste detection
- Local AI monitoring
- Audio intelligence
- Event logging
- Offline event queue
- Auto-sync when network returns
- Submit exam or assessment

### 4.2 Invigilator Dashboard

The invigilator dashboard is used during live exams.

Required features:

- Live student list
- Online/offline status
- Risk status
- Alert feed
- Student session timeline
- Send warning
- Add manual note
- Mark false alert
- Escalate case
- Export incident report

### 4.3 Exam Officer Review Dashboard

Required features:

- View flagged sessions
- Review evidence timeline
- Read AI summary
- Add official decision
- Clear false positives
- Escalate serious cases to HoD
- Export official report

### 4.4 HoD / Chief Exam Officer Dashboard

Required features:

- Review serious misconduct cases
- Approve department-level decision
- Request more review
- Forward confirmed cases to Academic Records
- Forward severe cases to disciplinary committee

### 4.5 Academic Records Dashboard

Required features:

- View finalized cases
- Attach outcome to student record
- Maintain misconduct history
- Export final reports
- Maintain audit trail

---

## 5. Agentic AI Modules

The system should be built as multiple specialized agents.

### 5.1 Identity Agent

Confirms that the student taking the exam is the registered student.

Inputs:

- Student profile
- Face image
- Login data
- Device data
- Exam session ID

Outputs:

- Identity verified
- Identity uncertain
- Identity failed
- Human approval required

### 5.2 Environment Agent

Detects physical-environment issues.

Detects:

- Extra person
- Phone
- Book/paper
- Calculator if prohibited
- Student leaving camera
- Camera blocked
- Poor lighting
- Suspicious movement

### 5.3 Screen Agent

Detects computer-behavior violations.

Detects:

- Tab switching
- App switching
- Copy/paste
- Screen sharing
- Remote desktop
- Multiple monitors
- Exam window minimized
- Unauthorized browser activity

### 5.4 Audio Intelligence Agent

Separates normal environmental noise from suspicious human communication.

Detects:

- Human voice
- Whispering
- Multiple voices
- Fan noise
- Air conditioner
- Generator
- Car/traffic
- Motorcycle
- Keyboard sound
- Mouse click
- Door sound
- Chair movement
- Phone ringtone
- Audio playback from another device

Important rule: environmental noise should not automatically become misconduct. Human communication should increase risk depending on duration, repetition, and supporting evidence.

### 5.5 Voice Source Distance and Direction Agent

Estimates whether a voice is coming from the student, another person nearby, or far background noise.

MVP method:

- Detect human voice
- Measure loudness against baseline
- Check voice duration
- Check whether the student's mouth is moving
- Estimate source as near, same-room, or far-background
- Mark external voice suspicion if voice is heard while the student's mouth is not moving

Advanced method:

- Use stereo microphone or USB microphone array
- Estimate left/right/front/back direction
- Estimate distance band
- Detect multiple voice sources

Technical limitation: with only one microphone, the system must not promise exact distance in meters. It should estimate distance categories only.

### 5.6 Behavior Agent

Detects suspicious behavior patterns over time.

Detects:

- Frequent looking away
- Sudden long pause
- Repeated interruptions
- Suspicious answer speed
- Sudden writing-style change
- Multiple suspicious events close together
- Repeated disconnections

### 5.7 AI-Cheating Detection Agent

Detects possible use of generative AI or external assistance.

Detects:

- Long pasted answer
- Sudden writing-style change
- Very fast essay completion
- Similar answers among students
- Opening AI tools
- Suspicious app switching
- Repeated copy/paste behavior

Important rule: AI-written-text suspicion must not be used as final proof. It should only support human review.

### 5.8 Risk Agent

Combines all events and calculates a risk score.

Inputs:

- Identity events
- Camera events
- Audio events
- Screen events
- Behavior events
- Exam rules
- Manual invigilator notes

Outputs:

- Risk score
- Risk level
- Risk explanation
- Recommended action
- Escalation status

### 5.9 Evidence Agent

Creates structured evidence for human review.

Outputs:

- Event timeline
- Evidence screenshots
- Short audio clips for high-risk events
- Short video clips where required
- AI explanation
- Risk summary
- Human reviewer comments
- Final decision record

### 5.10 Policy Agent

Checks incidents against exam rules.

Example: if calculator is allowed, calculator detection should not increase risk. If calculator is prohibited, calculator detection should increase risk.

### 5.11 Human Escalation Agent

Routes serious cases to the correct human reviewer.

Escalation flow:

- Medium risk: invigilator monitoring
- High risk: invigilator action and exam officer review
- Critical risk: invigilator, exam officer, and HoD review

---

## 6. Risk Scoring Engine

The first version should use a clear rule-based scoring system. Machine learning can be added later.

### 6.1 Example Risk Points

| Event | Points |
|---|---:|
| Face missing for more than 10 seconds | +10 |
| Face missing for more than 30 seconds | +20 |
| Multiple faces detected | +25 |
| Phone detected | +30 |
| Student leaves camera | +20 |
| Repeated looking away | +10 |
| Tab/window switch | +15 |
| Copy/paste detected | +20 |
| Long answer pasted suddenly | +25 |
| Remote desktop detected | +50 |
| Screen sharing detected | +50 |
| Camera blocked | +30 |
| Human voice under 3 seconds | +5 |
| Human voice 3-10 seconds | +10 |
| Human voice over 10 seconds | +20 |
| Voice detected but mouth not moving | +25 |
| Voice from side/back direction | +30 |
| Multiple voices detected | +35 |
| Phone ringtone/notification | +25 |
| Audio from another device | +35 |

### 6.2 Risk Levels

| Score | Level | Meaning |
|---:|---|---|
| 0-20 | Low | Normal session |
| 21-50 | Medium | Monitor closely |
| 51-80 | High | Invigilator review required |
| 81+ | Critical | Immediate escalation |

### 6.3 Risk Rules

- One minor event should not punish a student.
- Repeated events should increase risk.
- Critical events should trigger immediate alert.
- Risk should reduce slowly when behavior returns to normal.
- False alerts must be marked by reviewers.
- Human officials must make final decisions.

---

## 7. Audio Intelligence Design

### 7.1 Purpose

The audio system separates normal environmental noise from suspicious human communication.

Expected environmental sounds include:

- Fan
- Generator
- Car
- Motorcycle
- Neighbors talking
- Hostel noise
- Keyboard sound
- Phone sound

### 7.2 Workflow

1. Record a 10-20 second local audio baseline before the exam starts.
2. Detect whether human voice exists.
3. Classify the sound type.
4. Check duration and repetition.
5. Match voice with student mouth movement.
6. Send only event logs and high-risk clips to the backend.

### 7.3 Audio Risk Categories

| Audio Event | Risk |
|---|---|
| Fan | Low |
| Generator | Low |
| Vehicle | Low |
| Keyboard/mouse | Low/medium |
| Door/chair movement | Low |
| Human speech | Medium |
| Whispering | High |
| Multiple voices | High |
| Phone ringtone | High |
| Audio playback | High |
| Voice while mouth not moving | High |

---

## 8. Voice Distance and Direction Design

### 8.1 MVP Version

The MVP should classify voice source into three categories:

1. Near/student area
2. Same-room external voice
3. Far-background voice

Inputs:

- Microphone loudness
- Noise baseline
- Voice duration
- Camera mouth movement
- Face position
- Audio confidence

Example output:

```json
{
  "event": "human_voice_detected",
  "estimated_source": "same_room_external",
  "distance_band": "1-3 meters",
  "student_mouth_moving": false,
  "confidence": 0.76,
  "risk": "high"
}
```

### 8.2 Advanced Version

The advanced version should support:

- Stereo microphone
- USB microphone array
- Voice from left/right/front/back
- Multiple voice sources
- Distance band estimation
- Source movement tracking

This can later connect to ProctorScan One hardware.

---

## 9. Proctoring Dataset Bank

### 9.1 Purpose

The system should store useful data so K-SLAS can train its own proprietary proctoring AI models later.

We should not start by training one giant foundation model. We should first collect data and fine-tune specialized models.

### 9.2 Dataset Types

Audio dataset:

- Fan
- Generator
- Car/traffic
- Motorcycle
- Keyboard
- Mouse click
- Door
- Chair
- Human voice
- Whispering
- Multiple voices
- Phone ringtone
- AI assistant voice
- Background classroom noise

Vision dataset:

- Student face visible
- No face
- Multiple faces
- Phone visible
- Book visible
- Paper visible
- Calculator visible
- Student looking away
- Student leaving camera
- Camera blocked
- Another person behind student
- Poor lighting

Screen behavior dataset:

- Tab switch
- Copy/paste
- External app opened
- Remote desktop detected
- Multiple monitor detected
- Long answer pasted
- Screenshot attempt
- Exam minimized
- Internet disconnected
- Suspicious answer timing

Final decision dataset:

- AI risk score
- Invigilator comment
- Exam officer decision
- HoD decision
- Final status
- Appeal result
- False positive status

### 9.3 Dataset Storage Structure

```text
proctoring-dataset/
  raw/
    audio/
    images/
    short-clips/
    event-logs/
  processed/
    audio-features/
    image-labels/
    risk-events/
  labels/
    audio-labels.jsonl
    vision-labels.jsonl
    behavior-labels.jsonl
    final-decisions.jsonl
  training/
    train/
    validation/
    test/
  models/
    audio/
    vision/
    behavior/
    risk-scoring/
  reports/
    evaluation-results/
```

### 9.4 Privacy Rules

- Use clear privacy notice.
- Use university-approved legal basis or consent.
- Minimize data collection.
- Encrypt evidence storage.
- Use role-based access control.
- Keep access audit logs.
- Anonymize data where possible.
- Keep retention configurable.
- Provide student appeal process.
- Do not use AI as the final disciplinary authority.

---

## 10. Evidence Storage Strategy

### 10.1 Clean Students

Save only:

- Attendance
- Login time
- Submission time
- Final risk score
- System health summary

Do not save full video/audio for clean students by default.

### 10.2 Flagged Students

Save:

- Event logs
- Screenshots around suspicious events
- Short audio clips around suspicious events
- Short video clips if required
- AI summary
- Invigilator comments
- Review decisions

### 10.3 Serious Misconduct Cases

Save:

- Full incident package
- Evidence bundle
- Final decision
- Appeal history
- Audit trail

---

## 11. Suggested Backend Tables

### Users

- id
- name
- email
- phone
- role
- department_id
- status
- created_at
- updated_at

### Students

- id
- user_id
- matric_number
- department_id
- level
- face_profile_url
- status
- created_at

### Courses

- id
- code
- title
- department_id
- level
- semester

### Exams

- id
- course_id
- title
- exam_type
- duration_minutes
- start_time
- end_time
- rules
- status
- created_by

### Exam Sessions

- id
- exam_id
- student_id
- device_id
- start_time
- end_time
- submission_time
- risk_score
- risk_level
- status

### Proctoring Events

- id
- session_id
- event_type
- event_time
- severity
- confidence
- points
- evidence_url
- metadata
- created_at

### Audio Events

- id
- session_id
- sound_type
- duration_seconds
- confidence
- estimated_source
- distance_band
- mouth_moving
- risk_points
- evidence_url
- created_at

### Vision Events

- id
- session_id
- object_type
- confidence
- bounding_box
- risk_points
- evidence_url
- created_at

### Screen Events

- id
- session_id
- event_type
- app_name
- window_title
- risk_points
- metadata
- created_at

### Incident Reports

- id
- session_id
- risk_score
- risk_level
- ai_summary
- reviewer_comment
- final_decision
- status
- created_at

### Review Actions

- id
- incident_report_id
- reviewer_id
- action
- comment
- created_at

### Audit Logs

- id
- actor_id
- action
- entity_type
- entity_id
- ip_address
- timestamp

---

## 12. MVP Scope

### 12.1 Student App MVP

- Login
- Exam list
- Device check
- Camera check
- Microphone check
- Face verification
- Full-screen exam mode
- Tab/app switch detection
- Copy/paste detection
- Face presence detection
- Multiple-face detection
- Basic phone detection
- Human voice detection
- Audio baseline
- Event logging
- Risk scoring
- Exam submission

### 12.2 Invigilator Dashboard MVP

- Live student list
- Student status
- Risk level
- Alert feed
- Student timeline
- Send warning
- Mark false alert
- Escalate case
- Export basic incident report

### 12.3 Backend MVP

- Authentication
- Role management
- Exam creation
- Student session tracking
- Event ingestion
- Risk scoring
- Evidence storage
- Incident report generation
- Review workflow
- Audit logs

### 12.4 AI MVP

- Local face detection
- Local multiple-face detection
- Local phone/object detection
- Local human voice detection
- Local audio classification basic version
- Rule-based risk scoring
- Cloud AI summary for high-risk cases only

---

## 13. Build Order

### Step 1: Backend Foundation

Build:

- Auth
- Roles
- Students
- Courses
- Exams
- Exam sessions
- Event logging
- Risk score tables
- Incident reports
- Audit logs

### Step 2: Student App Foundation

Build:

- Login
- Exam list
- Start exam
- Submit exam
- Full-screen mode
- Heartbeat
- Event sync
- Offline queue

### Step 3: Basic Proctoring Events

Build:

- Tab switch detection
- Copy/paste detection
- Window/app switch detection
- Camera on/off detection
- Microphone on/off detection
- Network disconnect detection

### Step 4: Local AI MVP

Build:

- Face presence detection
- Multiple-face detection
- Phone detection
- Human voice detection
- Audio noise baseline

### Step 5: Risk Scoring Engine

Build:

- Event points
- Risk score update
- Risk level update
- Alert thresholds
- Risk timeline

### Step 6: Invigilator Dashboard

Build:

- Live exam list
- Student status
- Risk summary
- Alert feed
- Student timeline
- Send warning
- Escalate case

### Step 7: Incident Report System

Build:

- Auto-create incident for high-risk sessions
- Timeline report
- Evidence attachment
- Reviewer comment
- Final decision
- Export PDF

### Step 8: Cloud AI Summary

Build:

- Send event logs only
- Generate incident explanation
- Generate human-readable report
- Store AI summary
- Allow reviewer to accept/edit/reject AI summary

### Step 9: Dataset Bank

Build:

- Store labeled audio clips
- Store labeled images
- Store behavior logs
- Store final decisions
- Create labeling workflow
- Export training dataset

### Step 10: Advanced AI

Build:

- Audio classification model
- Voice distance estimation
- Mouth movement matching
- Behavior anomaly model
- Custom risk model

---

## 14. Technical Stack Direction

### Current project direction

The current K-SLAS app is a Flutter project. The app already includes Flutter dependencies for camera, Windows camera support, screen protection, Bluetooth/network checks, sensors, audio recording, FFT audio processing, LiveKit, HTTP, and storage.

This supports the proctoring direction because many required device-level capabilities are already present in the project dependencies.

### Recommended additions later

- Local ML inference runtime
- On-device face detection
- On-device object detection
- On-device audio classification
- Secure evidence upload
- Background event queue
- Backend event ingestion API

---

## 15. Cost Control Rules

To keep AI cost very low:

- Do not send live video of all students to cloud AI.
- Do not transcribe all audio.
- Do not generate reports for clean sessions.
- Do not store full video for every student.
- Use local AI for continuous monitoring.
- Use cloud AI only for flagged sessions.
- Use batch processing for reports.
- Store short clips only for suspicious events.
- Keep clean-student records minimal.

---

## 16. Final Build Statement

K-SLAS Agentic AI Proctoring will provide a low-cost, scalable, and intelligent examination monitoring system. It will support desktop, laptop, tablet, and iPad examinations, while allowing mobile-phone graded assessments where appropriate.

The system will process camera, audio, screen, and behavior signals locally, assign risk scores using rule-based and AI-supported methods, and escalate suspicious sessions to invigilators and examination officials.

The first version should focus on the MVP: student exam app, device checks, exam lockdown, face detection, audio detection, screen monitoring, risk scoring, invigilator dashboard, and incident reporting. Advanced features such as voice distance estimation, proprietary AI models, microphone arrays, and ProctorScan hardware integration should come after the MVP is stable.
