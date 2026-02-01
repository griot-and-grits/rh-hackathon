# Feedback Feature

## Description

Full-stack user feedback mechanism allowing public users to report issues on Griot AI responses and video/artifact content. Admins can view, filter, and manage feedback from the admin dashboard.

## Implementation Checklist

### Backend (gng-backend)

- [x] `app/models/feedback.py` — Created: FeedbackType, FeedbackStatus, Feedback, FeedbackCreateRequest, FeedbackStatusUpdateRequest
- [x] `app/models/__init__.py` — Modified: added feedback model exports
- [x] `app/services/db.py` — Modified: added feedback indexes and CRUD methods (insert_feedback, get_feedback, update_feedback, list_feedback, count_feedback)
- [x] `app/services/feedback_service.py` — Created: FeedbackService with create, update_status, get, list methods
- [x] `app/factory.py` — Modified: wired FeedbackService (always available, no conditional)
- [x] `app/api/feedback.py` — Created: FastAPI router with POST, GET, GET/:id, PATCH/:id/status
- [x] `app/api/__init__.py` — Modified: exported feedback_router
- [x] `app/server.py` — Modified: included feedback router, added to root endpoint

### Frontend API Layer (gng-web)

- [x] `lib/admin/types.ts` — Modified: added FeedbackType, FeedbackStatus, Feedback, FeedbackCreateRequest, FeedbackStatusUpdateRequest, FeedbackListResponse
- [x] `lib/admin/apis/feedback.ts` — Created: feedbackApi with create, getById, updateStatus, list
- [x] `lib/admin/apis/index.ts` — Modified: exported feedback API

### Frontend Public (gng-web)

- [x] `components/feedback/feedback-modal.tsx` — Created: feedback submission dialog with form, success/error states
- [x] `components/collections.tsx` — Modified: added Flag icon import, FeedbackModal import, feedback state/helpers, "Report issue" on chat messages, "Report Issue" on video cards, modal render

### Frontend Admin (gng-web)

- [x] `lib/admin/status.ts` — Modified: added FEEDBACK_STATUS_STYLES, FEEDBACK_TYPE_STYLES, getFeedbackStatusStyle, getFeedbackTypeStyle
- [x] `components/admin/shared/feedback-status-badge.tsx` — Created: status badge component
- [x] `components/admin/shared/feedback-type-badge.tsx` — Created: type badge component
- [x] `components/admin/feedback/feedback-table.tsx` — Created: admin feedback table with stat cards, search, type/status filters, artifact links, detail dialog with admin notes editing, and pagination
- [x] `app/admin/feedback/page.tsx` — Created: admin page route
- [x] `components/admin/shell/admin-shell.tsx` — Modified: added Feedback nav item with Flag icon
- [x] `app/admin/page.tsx` — Modified: added "Review Feedback" quick action card

### Documentation (rh-hackathon)

- [x] `docs/FEEDBACK.md` — Created: feature documentation
- [x] `backlog/feedback-feature.md` — Created: this file

## Design Decisions

1. **No authentication for submission**: The POST /feedback/ endpoint is public so any visitor can report issues without needing to sign in.

2. **Plain axios on public page**: The public Collections page has no QueryClientProvider, so the FeedbackModal uses plain axios via `feedbackApi.create()` with `useState` for loading/error/success state instead of `useMutation`.

3. **Single modal instance pattern**: One `<FeedbackModal>` instance in Collections with dynamic context via state, rather than one per chat message or video card.

4. **Detail dialog for actions**: Admin feedback table uses a "View" button to open a detail dialog where admins can review full context, edit admin notes, and change status via a "Save Changes" action, rather than inline status dropdowns.

5. **FeedbackService always available**: Unlike CollectionService (conditional on Globus), FeedbackService is always initialized since it only depends on MongoDB.
