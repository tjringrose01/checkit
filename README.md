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

## Detailed Technical Requirements

### Security Requirements

- The application must be designed and implemented in alignment with OWASP Top 10 secure coding practices.
- Input validation must always be performed server-side for all user-controlled input.
- Frontend validation may improve UX, but it must never replace server-side validation.
- Output encoding, authorization checks, secure session handling, dependency hygiene, and error handling must be implemented with OWASP Top 10 risks in mind.
- Security-sensitive functionality must default to deny unless explicitly authorized.
- Secrets must never be stored in source code.
- Secrets must be injected through environment configuration or CI/CD-managed secret storage.

### Authentication

- Authentication must use `user_id` and password for login.
- The system must store users in a `users` table.
- The `users` table must include at least:
  - `id`
  - `user_id`
  - `email`
  - `password_digest`
  - `role`
  - `failed_login_attempts`
  - `locked_at`
  - `last_login_at`
  - `must_change_password`
  - `created_at`
  - `updated_at`
- `user_id` must be unique and treated as the primary login identifier.
- Passwords must never be stored in plaintext.
- Password hashing must use Rails `has_secure_password` with BCrypt, or an equivalent industry-standard password hashing mechanism supported by Rails.
- The application must use authenticated web sessions for protected functionality.
- Only authenticated users may access checklist functionality.
- The login form must authenticate with `user_id` and password, not email.
- `last_login_at` must be recorded after each successful login.
- The application must support a forced password change flow for users flagged with `must_change_password`.

### Initial Deployment Bootstrap Requirements

- The first application deployment must create an initial administrative user.
- The initial admin account must use:
  - `user_id`: `admin`
  - password: `password`
- The initial admin account must be marked with `must_change_password = true`.
- The initial admin user must be required to change the password immediately after the first successful login before accessing the rest of the application.
- The initial admin bootstrap process must be idempotent and must not create duplicate admin accounts on repeated deployments.
- The bootstrap implementation must be clearly documented because it intentionally creates a temporary default credential.
- Implementation clarification:
  - the app reads `BOOTSTRAP_ADMIN_PASSWORD` from runtime environment configuration
  - the bootstrap password is not hardcoded in source control
  - if you need to mirror the original issue text exactly, set `BOOTSTRAP_ADMIN_PASSWORD=password` before startup

### Password Rules

- Passwords must have a minimum length of 12 characters.
- Password validation must happen server-side.
- The system should reject obviously weak passwords if a practical Rails-compatible approach is available.
- Authentication failures must return a generic error message that does not reveal whether the `user_id` or password was incorrect.
- The password change flow must require the initial default admin password to be replaced with a compliant password.

### Failed Login Lockout

- A user account must be locked after more than 5 consecutive failed login attempts.
- `failed_login_attempts` must increment on each failed login.
- `failed_login_attempts` must reset to `0` after a successful login.
- When the lockout threshold is exceeded, `locked_at` must be set.
- Locked accounts must not be allowed to authenticate until an Admin unlocks the account or a documented unlock policy is implemented.
- The initial implementation should support Admin-driven unlocks through the management interface.
- The lockout response must use a generic message and must not expose unnecessary account state details.
- Lockout logic must be enforced server-side.

### Email Requirements

- Every user must have an email address.
- `email` must be required and unique.
- Email addresses must be normalized before storage:
  - trim surrounding whitespace
  - convert to lowercase
- Email validation must be guided by RFC 5321 and RFC 5322.
- The implementation may use a practical validation subset rather than supporting every RFC-permitted edge case.
- The accepted validation strategy must favor deliverability, interoperability, and predictable application behavior over exhaustive acceptance of obscure but technically valid address formats.
- Email format must be validated server-side.
- Validation must reject clearly invalid addresses, including:
  - missing `@`
  - missing domain
  - spaces
  - malformed local or domain parts
- Email length must be capped at a reasonable maximum consistent with common web application practice.
- Email validation must be implemented in the Rails model layer, not only in the frontend.
- Outbound email must use the Mailgun API.
- Mailgun authentication credentials must be provided through CI/CD-managed secrets or runtime environment secrets.
- Mailgun API keys or tokens must never be committed to the repository or hardcoded in application source.

### User ID Requirements

- `user_id` must be required and unique.
- `user_id` must be normalized according to a documented policy before storage.
- The initial implementation must normalize `user_id` by trimming surrounding whitespace and converting the value to lowercase.
- `user_id` must be validated for:
  - minimum length of 4 characters
  - maximum length of 50 characters
  - allowed characters limited to lowercase letters, numbers, underscore, hyphen, and period

### Authorization And Roles

- The application must support at least two roles:
  - `admin`: can create, upload, edit, delete, lock, unlock, and manage checklists and checklist items, and manage user access required for checklist operations
  - `user`: can view and interact with checklists that are available to them
- Authorization must be enforced server-side on every protected action.
- Frontend route guards or conditional rendering may improve UX, but frontend checks must never replace backend authorization.

### Checklist And Data Model

- The application must support checklist entities and checklist item entities.
- A checklist must have at least:
  - title
  - description or notes field
  - status flag such as active/inactive
  - timestamps
- A checklist item must have at least:
  - checklist reference
  - item text
  - sort order
  - desired completion time
  - actual completion time when completed
  - deviation between desired completion time and actual completion time
  - completion state
  - timestamps
- Checklist completion changes made in the frontend must persist in the backend.
- The system must define whether completion state is global or per user.
- The initial implementation should treat checklist item completion as per-user state unless a later requirement overrides that behavior.
- Deviation from desired completion time to actual completion time must be calculated and displayed to the user.
- The deviation display must indicate whether completion was early, on time, or late.

### Management Interface

- The management interface must be accessible only to authenticated `admin` users.
- Admin users must be able to:
  - create checklists
  - edit checklists
  - delete checklists
  - create checklist items
  - edit checklist items
  - delete checklist items
  - upload checklist items in bulk
  - unlock locked user accounts
- The initial bulk upload format must be CSV.
- CSV upload validation must reject malformed files and return actionable validation errors.
- Bulk upload validation must apply the same server-side validation rules as manual checklist item creation.
- The current implementation also sends an account-unlocked email when an Admin unlocks a locked user.

### Frontend Requirements

- The frontend must be responsive and usable on modern iPhone and Android browsers.
- The initial support target should be current Safari on iPhone and current Chrome on Android as of April 23, 2026.
- The UI must allow users to:
  - sign in with `user_id` and password
  - complete a forced password change when required
  - view assigned or available checklists
  - check and uncheck checklist items
  - see persisted checklist state after refresh
  - see desired completion time, actual completion time, and deviation status for checklist items where applicable
- The admin UI must allow secure checklist and user-management actions appropriate to the `admin` role.

### Sync Behavior

- Checklist changes must be written to the backend immediately when the user changes item state.
- The frontend may use optimistic updates, but it must recover cleanly from backend failures.
- On failed checklist updates, the UI must show a user-visible error and restore the last confirmed backend state.
- Real-time multi-user synchronization is not required in the initial version.

### Database And Portability

- SQLite is the initial development database.
- The schema and application code must remain compatible with a later migration to PostgreSQL.
- The database design must avoid SQLite-only features that would complicate PostgreSQL migration.
- Unique indexes must be created for `user_id` and `email`.
- Constraints and validations should be implemented so behavior is consistent between SQLite and PostgreSQL.

### Containerization And Environment

- The application must run in a containerized local development environment.
- The repository should include a `Dockerfile` and a documented local startup flow.
- If multiple services are required, the repository should include `docker-compose.yml` or an equivalent container orchestration file for local development.

### Testing And Quality

- Core authentication, authorization, lockout, checklist interaction, CSV upload behavior, and forced password change behavior must have automated test coverage.
- Model validations for `user_id`, `email`, and password requirements must be tested.
- Lockout and unlock flows must be tested.
- Last-login tracking must be tested.
- Role-based access restrictions must be tested server-side.
- Validation behavior for both manual entry and CSV upload must be tested.
- Checklist timing and deviation calculations must be tested.

## Non-Negotiable Guardrails For AI Agents

- AI agents may implement changes only on `dev` or on feature branches created from `dev`.
- AI agents must never implement directly on `main`.
- AI agents must never merge, promote, or move work into `main`.
- Promotion from `dev` to `main` is reserved for the repository owner only.
- All AI-generated feature work must flow through a pull request into `dev`.
- AI agents must treat `main` as read-only except for inspection.
- AI agents must not change branch protection rules, default branch settings, or repository governance without explicit instruction from the repository owner.
- AI agents must not delete branches or rewrite branch history without explicit instruction from the repository owner.
- AI agents must not bypass review intent by pushing directly to protected or long-term branches.
- AI agents must document substantive requirement clarifications before implementation if those clarifications affect architecture, security, or data behavior.
- AI agents must preserve server-side enforcement for authentication, authorization, validation, and lockout rules.
- AI agents must not weaken password, session, validation, lockout, or secret-management requirements for convenience.
- AI agents must not hardcode credentials, API keys, tokens, or other secrets in source code.

## Project Flow

This repository should follow a controlled branch strategy.

- `main` is the default branch and the long-term protected branch.
- `dev` is the integration branch for active development.
- Feature work should be done in short-lived branches created from `dev`.
- Feature branches should open pull requests into `dev`.
- Routine development work must not be merged directly into `main`.
- Movement from `dev` to `main` is performed only by the repository owner.

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
6. The repository owner decides if and when `dev` changes move to `main`.

## Local Development

Issue `MVP-01` establishes the initial Rails-style project scaffold on `dev`.

### Current Bootstrap Contents

- Ruby on Rails application skeleton
- SQLite configuration for development and test
- Dockerfile for containerized development
- `docker-compose.yml` for local startup
- Health endpoint at `/up`
- Session-based authentication with forced password change and lockout protection
- Responsive user checklist dashboard with per-user completion state and timing deviation display
- Admin checklist management, checklist item management, CSV upload, and account unlock flow
- Action Mailer Mailgun delivery support via runtime environment secrets

### Start The App

1. Ensure Docker and Docker Compose are installed on the machine where you run the app.
2. Set `BOOTSTRAP_ADMIN_PASSWORD` in the shell before startup if you want the initial admin account to be created.
3. From the repository root, run `docker compose up --build`.
4. Open `http://localhost:3000`.
5. Confirm the health endpoint responds at `http://localhost:3000/up`.

### Runtime Environment Variables

- `BOOTSTRAP_ADMIN_PASSWORD`: creates the initial `admin` user when missing and flags that account for immediate password change
- `MAILGUN_API_KEY`: Mailgun private API key
- `MAILGUN_DOMAIN`: Mailgun sending domain
- `MAILGUN_FROM_ADDRESS`: optional sender address; defaults to `postmaster@MAILGUN_DOMAIN`
- `MAILGUN_BASE_URL`: optional Mailgun API base URL; defaults to `https://api.mailgun.net`
  - use `https://api.eu.mailgun.net` for EU-region domains

### Run Tests

1. From the repository root, run `docker compose run --rm -e RAILS_ENV=test web bin/rails test`

### Jenkins Container Build And Push

- The repository includes a `Jenkinsfile` that:
  1. checks out the branch Jenkins is building
  2. builds the application container from `Dockerfile`
  3. tags the image with the short Git SHA and sanitized branch name
  4. logs into the Docker registry with Jenkins-managed credentials
  5. pushes both tags to the configured repository

#### Jenkins Configuration

Create these Jenkins pipeline environment variables:

- `DOCKER_REGISTRY`
  - Example for Docker Hub: `docker.io`
  - Example for a private registry: `registry.example.com`
- `DOCKER_IMAGE_REPOSITORY`
  - Example for Docker Hub: `your-org/checkit`
  - Example for a private registry: `platform/checkit`
- `DOCKER_CREDENTIALS_ID`
  - Jenkins credentials ID for the registry login
  - Default expected by the `Jenkinsfile`: `docker-registry-credentials`

#### Create The Jenkins Secret

1. In Jenkins, open `Manage Jenkins` > `Credentials`.
2. Choose the credential store and domain used by the pipeline.
3. Click `Add Credentials`.
4. Set `Kind` to `Username with password`.
5. Enter the Docker registry username.
6. Enter the Docker registry password or access token.
7. Set `ID` to the value used by `DOCKER_CREDENTIALS_ID`.
   Example: `docker-registry-credentials`
8. Save the credential.

#### Create The Jenkins Job

1. Create a `Pipeline` job or a multibranch pipeline pointed at this repository.
2. Ensure the Jenkins agent has Docker CLI access and permission to run `docker build`, `docker login`, and `docker push`.
3. Set the environment variables above in the job configuration or folder configuration.
4. Run the pipeline.

#### Resulting Image Tags

- `${DOCKER_REGISTRY}/${DOCKER_IMAGE_REPOSITORY}:${short_git_sha}`
- `${DOCKER_REGISTRY}/${DOCKER_IMAGE_REPOSITORY}:${branch_name}`

### MVP Status

- The current branch implements the MVP scaffold, authentication flows, checklist interaction flow, admin management flow, CSV import flow, and Mailgun-backed outbound email configuration.
- Automated verification currently passes with `docker compose run --rm -e RAILS_ENV=test web bin/rails test`.
- Runtime verification currently passes with:
  1. `docker compose up -d`
  2. `curl http://localhost:3000/up`
  3. expected response: `{"status":"ok","service":"checkit"}`
  4. `docker compose down`

### Notes

- SQLite is used for the initial setup, but the file layout and config are structured so PostgreSQL migration can happen in a later issue.
- All implementation work must remain on `dev` or feature branches created from `dev`.
- Container startup runs `db:prepare` and `db:seed`, which bootstraps the initial admin account required by the project requirements.
- The bootstrap admin account uses `user_id` `admin`, reads its initial password from `BOOTSTRAP_ADMIN_PASSWORD`, and is flagged to force an immediate password change after first sign-in.
- The password is not committed to source control. Set it through environment configuration when the container starts.
- Mailgun delivery uses the official HTTP API endpoints at `/v3/{domain}/messages` and requires runtime secrets rather than committed credentials.

## Suggested Initial Milestones

1. Bootstrap a Rails application and Docker-based local environment.
2. Define users, roles, checklists, checklist items, per-user checklist state, and checklist timing fields.
3. Implement `user_id` and password authentication with email validation, last-login tracking, forced password change, and login lockout protection.
4. Build checklist viewing, item completion, and timing deviation display flows.
5. Build the admin management interface for checklist creation, CSV uploads, account unlock actions, and initial operational management.
6. Integrate Mailgun using CI/CD-managed secrets and prepare the application for an eventual PostgreSQL migration.
