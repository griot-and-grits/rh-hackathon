# User Feedback Feature

## Overview

The feedback feature allows users to report issues with Griot AI responses, video content, and transcript accuracy directly from the public Collections page. Admins can view, filter, and manage feedback from the admin dashboard.

## API Endpoints

All endpoints are served from the backend at `/feedback`.

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/feedback/` | Submit feedback (public, no auth) |
| `GET` | `/feedback/` | List feedback with optional filters |
| `GET` | `/feedback/{feedback_id}` | Get single feedback by ID |
| `PATCH` | `/feedback/{feedback_id}/status` | Update status and admin notes |

### Query Parameters (GET /feedback/)

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status: `new`, `reviewed`, `resolved`, `dismissed` |
| `feedback_type` | string | Filter by type: `transcript_accuracy`, `griot_response`, `content_issue`, `other` |
| `limit` | int | Max results (1-100, default 50) |
| `skip` | int | Pagination offset (default 0) |

### POST /feedback/ Request Body

```json
{
  "description": "The response mentioned incorrect dates",
  "feedback_type": "griot_response",
  "artifact_id": "video-123",
  "artifact_title": "Interview with Jane Doe",
  "chat_user_message": "Tell me about the 1960s movement",
  "chat_assistant_message": "The movement began in 1975...",
  "submitter_name": "John Smith",
  "submitter_email": "john@example.com"
}
```

Required: `description`, `feedback_type`. All other fields are optional.

### PATCH /feedback/{id}/status Request Body

```json
{
  "status": "reviewed",
  "admin_notes": "Confirmed inaccuracy, will update knowledge base"
}
```

## Data Model

### FeedbackType

| Value | Description |
|-------|-------------|
| `transcript_accuracy` | Issues with video transcription |
| `griot_response` | Problems with AI-generated responses |
| `content_issue` | Issues with video or artifact content |
| `other` | General feedback |

### FeedbackStatus

| Value | Description |
|-------|-------------|
| `new` | Just submitted, not yet reviewed |
| `reviewed` | Admin has seen it |
| `resolved` | Issue has been addressed |
| `dismissed` | Determined not actionable |

### Feedback Schema

| Field | Type | Description |
|-------|------|-------------|
| `feedback_id` | string | Unique ID (e.g., `fb_a1b2c3d4e5f6`) |
| `description` | string | User's description of the issue |
| `feedback_type` | FeedbackType | Category of feedback |
| `status` | FeedbackStatus | Current review status |
| `artifact_id` | string? | Related video/artifact ID |
| `artifact_title` | string? | Related video/artifact title |
| `chat_user_message` | string? | User's chat message (for Griot feedback) |
| `chat_assistant_message` | string? | Griot's response (for Griot feedback) |
| `submitter_name` | string? | Optional submitter name |
| `submitter_email` | string? | Optional submitter email |
| `admin_notes` | string? | Notes added by admin |
| `created_at` | datetime | Submission timestamp |
| `updated_at` | datetime? | Last update timestamp |

## User Flow

### Public-facing (Collections page)

1. **Griot AI responses**: After the Griot responds to a question, a "Report issue" link appears below each assistant message. Clicking it opens the feedback modal pre-filled with the Griot response context.

2. **Video cards**: Each video card in the collection grid has a "Report Issue" button. Clicking it opens the feedback modal pre-filled with the video title.

3. **Modal**: Users select an issue type, describe the problem, and optionally provide their name and email. On submission, a success banner confirms the report was received.

### Admin Dashboard

1. Navigate to `/admin/feedback` or click "Review Feedback" on the dashboard.
2. Filter by status and/or feedback type using the dropdown filters.
3. Click a row to expand and see full details (description, context, submitter info).
4. Change status via the inline dropdown in the Actions column.

## MongoDB

- **Collection name**: `feedback`
- **Indexes**: `feedback_id` (unique), `status`, `feedback_type`, `artifact_id`, `created_at`
