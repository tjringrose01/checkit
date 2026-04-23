# Checkit

Checkit is a checklist application with a web-based frontend and backend API. The initial project setup should satisfy the following product and technical requirements.

## App Requirements

1. Backend Framework: Build the backend in Ruby on Rails and run it in a containerized environment such as Docker.
2. Database: Start with SQLite for lightweight local storage, while keeping the application compatible with a future migration to PostgreSQL.
3. Web Frontend: Build a responsive web frontend using a modern framework such as React or Vue. The interface must work well in iPhone and Android browsers.
4. Checklist Interaction: Users must be able to view checklist items, check them off, and have those changes synced with the backend.
5. Management Interface: Authorized users must have a secure web interface for uploading and managing checklist items.
6. User Roles: Support at least two roles:
   - Checklist Creator / Admin: can create and manage checklists.
   - User: can view and interact with checklists.

## Recommended Technical Direction

- Backend: Ruby on Rails API or full-stack Rails application
- Containerization: Docker with a clear local development setup
- Database: SQLite in early development, with schema and adapter choices that keep PostgreSQL migration straightforward
- Frontend: React or Vue, optimized for responsive mobile-first interaction
- Auth and authorization: role-aware access control for Admin and User workflows

## Project Flow

This repository should follow a controlled branch strategy.

- `main` is the default branch and the long-term protected branch.
- `dev` is the integration branch for active development.
- Feature work should be done in short-lived branches created from `dev`.
- Feature branches should open pull requests into `dev`.
- Work should not be merged directly into `main` as part of normal feature delivery.

### Branch Naming

Use descriptive feature branch names, for example:

- `feature/checklist-api`
- `feature/mobile-checklist-ui`
- `feature/admin-checklist-management`

### Expected Workflow

1. Start from the latest `dev` branch.
2. Create a feature branch for a focused piece of work.
3. Implement and test the change in the feature branch.
4. Open a pull request from the feature branch into `dev`.
5. Keep `main` isolated from routine development work.

## Suggested Initial Milestones

1. Bootstrap a Rails application and Docker-based local environment.
2. Define checklist, checklist item, user, and role models.
3. Implement authentication and authorization.
4. Build checklist viewing and item completion flows.
5. Build the admin management interface for checklist creation and uploads.
6. Prepare the application for an eventual PostgreSQL migration.
