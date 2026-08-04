# Sample roadmap

A stand-in for whatever file defines "done" on your project. The checklist bar
counts every `- [x]` and `- [ ]` it finds, across any headings.

## Auth

- [x] Session cookie parsing
- [x] Password hashing with argon2
- [x] Login and logout routes
- [ ] Wire up refresh tokens
- [ ] Rate limit the login endpoint

## API

- [x] Health check endpoint
- [x] Request ID middleware
- [x] Error envelope format
- [x] Pagination helpers
- [ ] Bulk write endpoint
- [ ] Idempotency keys

## Storage

- [x] Migration runner
- [x] Connection pooling
- [ ] Read replica routing
- [ ] Soft deletes

## Observability

- [x] Structured logging
- [x] Request tracing
- [ ] Metrics export
- [ ] Alert rules

## Release

- [x] CI pipeline
- [ ] Staging deploy
- [ ] Production runbook
