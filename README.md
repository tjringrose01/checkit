# Checkit

Checkit is a checklist application with a web-based frontend and backend API. The initial project setup should satisfy the following product and technical requirements.

## App Requirements

1. Backend Framework: Build the backend in Ruby on Rails and run it in a containerized environment such as Docker.
2. Database: Start with SQLite for lightweight local storage, while keeping the application compatible with a future migration to PostgreSQL.
3. Web Frontend: Build a responsive web frontend using a modern framework such as React or Vue. The interface must work well in iPhone and Android browsers.
4. Checklist Interaction: The main user landing page must show a list of available checklists. Users must be able to open a specific checklist, view only that checklist's items, check them off, and have those changes synced with the backend.
   - Checklist item content should support rendering stored HTML in the application UI.
   - Development builds should include a default `SPL-Shakedown Checklist` so the app has representative checklist data immediately after setup.
   - Each checklist must have a start time.
   - Each checklist item's desired time must be stored as a number of minutes relative to the checklist start time.
   - Checklist start time is time-of-day only and must not depend on a stored date.
   - The application must accept checklist start times such as `7:00 PM`.
   - Marking a checklist item complete or incomplete should update the current page in place without a full page refresh or loss of scroll position.
   - Checklist percent-complete should be calculated from target times when target offsets are available, and should fall back to task-count progress when target times are not meaningfully set.
   - Displayed checklist times must render in the browser's local time rather than fixed UTC output.
   - Unless otherwise specified, displayed times must use the format `MM/DD/YY hh:mm AM/PM TZ`.
5. Management Interface: Authorized users must have a secure web interface for uploading and managing checklist items.
   - The admin workspace must start with a list of checklists.
   - Admin users must open a specific checklist before managing that checklist's items.
   - Checklist metadata editing and checklist item management must happen from the same checklist workspace rather than separate admin pages.
   - The admin workspace must also expose an admin-only user management area.
   - The user management area must support role assignment, password resets, enable and disable actions, unlock actions, and user deletion.
   - Admin accounts must not be disableable or deletable through the management interface.
   - Admin accounts must not have their role reassigned through the management interface.
6. User Roles: Support at least two roles:
   - Checklist Creator / Admin: can create and manage checklists.
   - User: can view and interact with checklists.
   - The application must support self-service registration for new `user` accounts.
7. Shared Footer: The application must display a shared footer on all pages, including the login page.
   - The footer should include common build and runtime metadata in this order: application name, copyright, environment or branch, build identifier, then built timestamp.
   - The built timestamp should render in the browser's local timezone.
8. Shared Header: The application must display a shared header on authenticated pages.
   - Clicking the application name or logo in the header should return the user to the home screen.
   - User actions such as signing out and opening the admin workspace should be available from a dropdown opened from the upper-right user bubble.
   - The authenticated checklist views should not repeat a `Signed in as ...` banner in the page body.

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
- The CI pipeline must run a SAST scanner against the Rails application.
- The initial SAST scanner must be Brakeman.
- SAST findings at the configured failure threshold must break the build.
- SAST reports generated by CI must be written into a repository path so they remain in the Jenkins workspace alongside the checked-out code.

### Authentication

- Authentication must use `user_id` and password for login.
- The login page must provide a self-service registration option for unauthenticated users.
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
- Self-service registration must create accounts only for the `user` role.
- Self-service registrants must never be able to assign themselves the `admin` role.
- Unverified self-service accounts must not be able to authenticate successfully.

### Self-Service Registration

- The application must support self-service registration from the login page.
- Registration must be available to unauthenticated users.
- Registration must collect at least:
  - `user_id`
  - `email`
  - password
  - password confirmation
- Registration must enforce the same server-side validation rules used for user creation and updates.
- Registration must normalize `user_id` and `email` before uniqueness checks and persistence.
- Registration must not be considered complete until the email address has been verified.
- The system must send a verification code to the submitted email address through Mailgun.
- The application must prompt the user to enter the verification code after registration submission.
- Verification must happen server-side.
- Verification codes must be securely generated.
- Verification codes should be short enough for manual entry.
  - recommended initial implementation: 6 digits
- Verification codes must expire after a defined time window.
  - recommended initial implementation: 15 minutes
- Verification codes must be single-use.
- The application must support resending verification codes for pending registrations.
- Resend operations must be rate-limited.
- Verification attempts must be rate-limited.
- Invalid, expired, or already-used verification codes must return generic failure messages.
- If an unverified registration already exists for the submitted identity, the application should update the pending verification flow rather than create duplicate records.
- The application should automatically sign the user in after successful verification, unless a later requirement changes that behavior.
- Pending or stale unverified registrations must be purgeable after a documented retention period.
  - recommended initial implementation: 24 to 72 hours
- The application should record:
  - registration creation time
  - verification send time
  - verification completion time

#### Registration Process Flow

1. An unauthenticated user opens the sign-in page.
2. The user selects the registration option.
3. The application collects `user_id`, `email`, password, and password confirmation.
4. The server validates and normalizes the submitted identity data.
5. The server creates a pending `user` account that is not yet eligible for authentication.
6. The server generates a verification code and sends it to the submitted email address through Mailgun.
7. The user is redirected to the verification page.
8. The user enters the verification code.
9. The server verifies that the code matches, is unexpired, and has not already been used.
10. The account is marked email-verified and becomes eligible for authentication.
11. The application signs the user in and redirects the user into the normal checklist flow.
12. If verification fails, the account remains pending until verification succeeds or the registration expires.

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
- A database-level unique index must be present for `email`.
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
- Self-service registration verification emails must be sent through the same server-side Mailgun integration.
- Email verification must be required before a self-service account becomes active.

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
- User administration functions such as password resets, enable and disable actions, unlock actions, and user deletion must be accessible only to authenticated `admin` users.
- Admin accounts must not be disableable or deletable through admin user-management actions.
- Role assignment must be accessible only to authenticated `admin` users.
- Self-service registrants must not be able to assign or elevate their own role.
- Self-service registration must create `user` accounts only.

### Checklist And Data Model

- The application must support checklist entities and checklist item entities.
- A checklist must have at least:
  - title
  - description or notes field
  - status flag such as active/inactive
  - start time
  - timestamps
- A checklist item must have at least:
  - checklist reference
  - item text
  - sort order
  - desired completion offset in minutes from the checklist start time
  - actual completion time when completed
  - deviation between desired completion time and actual completion time
  - completion state
  - timestamps
- Checklist completion changes made in the frontend must persist in the backend.
- The system must define whether completion state is global or per user.
- The initial implementation should treat checklist item completion as per-user state unless a later requirement overrides that behavior.
- Deviation calculations must treat checklist start time as time-of-day only and compare item target time against the actual completion date.
- Deviation calculations must compare the checklist target time against the user's browser-local completion wall clock and must not drift because of UTC date or timezone offsets.
- Actual completion display should assume the same day context and render as time-only unless a later requirement asks for the date.
- Checklist start time and calculated target time must render as wall-clock times and must not shift by timezone offset.
- Checklist progress percentage should use target-time progression when target offsets are available and should fall back to task-count progression otherwise.
- Deviation from desired completion time to actual completion time must be calculated and displayed to the user.
- The deviation display must indicate whether completion was early, on time, or late.

### Management Interface

- The management interface must be accessible only to authenticated `admin` users.
- Admin users must be able to:
  - start from a checklist list view in the admin workspace
  - open a user administration page from the admin workspace
  - open a specific user record to manage that user
  - open a specific checklist to manage its items
  - edit checklist title, status, notes, and start time from that same checklist workspace
  - create checklists
  - edit checklists
  - delete checklists
  - create checklist items
  - edit checklist items
  - delete checklist items
  - upload checklist items in bulk
  - assign roles to non-admin users
  - reset user passwords
  - enable users
  - disable users
  - unlock locked user accounts
  - delete users
- The initial bulk upload format must be CSV.
- CSV upload validation must reject malformed files and return actionable validation errors.
- Bulk upload validation must apply the same server-side validation rules as manual checklist item creation.
- The current implementation also sends an account-unlocked email when an Admin unlocks a locked user.
- Admin user-management actions must not allow any admin account to be disabled, deleted, or demoted away from the `admin` role.

### Development Seed Data

- Development builds should seed representative default checklist data.
- The default seeded checklist should include `SPL-Shakedown Checklist`.
- Default development seed data must be idempotent.
- Default development seed data must not be seeded into test or production builds unless a later requirement explicitly asks for it.

### Frontend Requirements

- The frontend must be responsive and usable on modern iPhone and Android browsers.
- The initial support target should be current Safari on iPhone and current Chrome on Android as of April 23, 2026.
- The UI must allow users to:
  - sign in with `user_id` and password
  - open a registration flow from the sign-in page
  - submit registration details including `user_id`, `email`, password, and password confirmation
  - enter an email verification code after registration
  - request a new verification code when allowed by rate limits
  - complete a forced password change when required
  - view assigned or available checklists as a checklist list page
  - open a specific checklist and see only that checklist's items
  - check and uncheck checklist items
  - see checklist percent-complete update as items are completed, using target-time progression when available
  - see persisted checklist state after refresh
  - see desired completion time, actual completion time, and deviation status for checklist items where applicable
- The admin UI must allow secure checklist and user-management actions appropriate to the `admin` role.
- The admin UI must provide an admin-only user management page for user access and password administration.
- The admin UI must provide role assignment controls for non-admin users.
- Admin checklist forms must use browser-compatible AM/PM time input formatting so checklist start times render and submit correctly.
- Checklist time displays must use browser-local rendering for start, scheduled, and actual completion times.
- Unless otherwise specified, checklist time displays must render as `MM/DD/YY hh:mm AM/PM TZ` in the browser timezone.
- Time-only checklist displays such as start, scheduled, and actual should render as `hh:mm AM/PM TZ`.
- Checklist start and target time displays should use `hh:mm AM/PM` wall-clock formatting without timezone shifting.
- A shared footer should be visible on application pages, including the sign-in page.
- The shared footer should show application and build metadata such as:
  - application name
  - copyright
  - environment or branch label
  - build identifier such as `dev-99`
  - build timestamp in the browser timezone
- A shared authenticated header should expose the home link from the application name/logo.
- The authenticated header should expose account actions from the upper-right user bubble menu instead of page-level sign-out/admin links.

### Sync Behavior

- Checklist changes must be written to the backend immediately when the user changes item state.
- The frontend may use optimistic updates, but it must recover cleanly from backend failures.
- On failed checklist updates, the UI must show a user-visible error and restore the last confirmed backend state.
- Checklist item completion changes should preserve the user's current page position and avoid unnecessary full-page reloads.
- Real-time multi-user synchronization is not required in the initial version.

### Database And Portability

- SQLite is the initial development database.
- The schema and application code must remain compatible with a later migration to PostgreSQL.
- The database design must avoid SQLite-only features that would complicate PostgreSQL migration.
- Every data table must include `created_at` and `updated_at`.
- `created_at` must be set when the row is created.
- `updated_at` must be updated every time the row is updated.
- Unique indexes must be created for `user_id` and `email`.
- Constraints and validations should be implemented so behavior is consistent between SQLite and PostgreSQL.

### Database Naming Conventions

To keep the schema readable and PostgreSQL-friendly, database objects should follow these naming conventions:

- Use lowercase `snake_case` for tables, columns, indexes, constraints, and foreign keys.
- Use plural nouns for table names.
  Examples: `users`, `checklists`, `checklist_items`
- Use descriptive column names rather than abbreviations where practical.
  Examples: `failed_login_attempts`, `desired_completion_offset_minutes`, `must_change_password`
- Prefer `{table_name}_id` for primary key columns in new tables when that does not conflict with existing framework conventions.
- Use `{referenced_table_singular}_id` for foreign key columns.
  Examples: `user_id`, `checklist_id`, `checklist_item_id`
- Name indexes with an `idx_` style prefix when creating explicit custom names.
  Example: `idx_checklist_items_sort_order`
- Name unique or alternate-key constraints with a `{table_name}_{column_name}_key` style when custom naming is needed.
- For import/export files and external identifiers, prefer explicit field names over generic names such as `id`.
  Example: use `checklist_item_id` instead of `id`
- Keep names explicit enough that PostgreSQL migrations, schema reviews, and future production operations remain easy to understand.

Reference used for these conventions:
- https://www.geeksforgeeks.org/postgresql/postgresql-naming-conventions/

### Containerization And Environment

- The application must run in a containerized local development environment.
- The repository should include a `Dockerfile` and a documented local startup flow.
- If multiple services are required, the repository should include `docker-compose.yml` or an equivalent container orchestration file for local development.

### Build And Release Traceability

- Every published container image must be traceable back to a specific source revision.
- CI builds must publish an immutable image tag based on the Git commit SHA.
- CI builds may also publish a semantic version tag when a release version is explicitly provided.
- Environment tags such as `dev`, `test`, and `prod` are deployment aliases and must not be treated as the only source of version identity.
- The application footer must display either:
  - an explicit application version, or
  - an immutable source revision such as the Git SHA
- The build metadata shown in the application should be consistent with the tags published by CI.

### Testing And Quality

- Core authentication, authorization, lockout, checklist interaction, CSV upload behavior, and forced password change behavior must have automated test coverage.
- Model validations for `user_id`, `email`, and password requirements must be tested.
- Lockout and unlock flows must be tested.
- Last-login tracking must be tested.
- Role-based access restrictions must be tested server-side.
- Validation behavior for both manual entry and CSV upload must be tested.
- Checklist timing and deviation calculations must be tested.
- Regression tests must cover checklist time rendering and submission, including browser-safe AM/PM time input formatting and non-Time-backed values used during rendering.
- Regression tests must cover browser-local time markup for displayed checklist times.
- Regression tests must cover deviation calculations against browser-local completion time so checklist timing does not drift by timezone offset.
- CI must run Brakeman as part of the quality gate before publishing container images.

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
- Dev-only default `SPL-Shakedown Checklist` seed data

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
- `APP_NAME`: optional application display name shown in the shared footer; defaults to `Checkit`
- `APP_VERSION`: optional semantic version or release label shown in the shared footer and baked into CI-built images when provided
- `APP_GIT_SHA`: optional Git commit SHA shown in the shared footer when `APP_VERSION` is not provided
- `APP_BUILD_ENVIRONMENT`: optional build or deployment environment label shown in the shared footer
- `APP_BUILD_NUMBER`: optional build number shown in the shared footer
- `APP_BUILD_TIMESTAMP`: optional build timestamp shown in the shared footer

#### Mailgun Runtime Setup

Set Mailgun values at container runtime. Do not bake them into the image through `Dockerfile` build arguments.

Recommended variables for this app:

- `MAILGUN_API_KEY`
- `MAILGUN_DOMAIN`
- `MAILGUN_FROM_ADDRESS`
- `MAILGUN_BASE_URL` when you need a non-default API endpoint

Example runtime values for the domain shown in current Mailgun examples:

- `MAILGUN_DOMAIN=mg.tjrcade.com`
- `MAILGUN_FROM_ADDRESS=Mailgun Sandbox <postmaster@mg.tjrcade.com>`
- `MAILGUN_BASE_URL=https://api.mailgun.net`

If you run the published image directly, pass the secrets at `docker run` time with `-e ...` flags or a runtime env file. Never commit that env file to the repository.

### Default Development Checklist Data

- `db:seed` includes a default `SPL-Shakedown Checklist` only when:
  - Rails is running in the `development` environment, and
  - `APP_BUILD_ENVIRONMENT=dev`
- The seed is idempotent and updates the checklist by title if it already exists.
- The default development checklist is not seeded for `test`, `prod`, or other non-dev build environments.

### Running A Published Docker Image

If you run the published Docker Hub image directly instead of `docker compose`, do not mount the entire `/app/db` directory from the host.

Why:

- `/app/db` in the image contains both the runtime SQLite database file and Rails source files needed for setup:
  - `db/migrate`
  - `db/schema.rb`
  - `db/seeds.rb`
- Mounting a host directory onto `/app/db` hides those files inside the container.
- If those files are hidden, `bin/rails db:prepare` cannot create the application schema, and tables such as `users` will be missing.

Use one of these approaches instead:

1. Do not mount `/app/db` at all if you do not need database persistence.
2. If you need SQLite persistence, mount only the database file, for example:
   - `~/checkit_dev/development.sqlite3:/app/db/development.sqlite3`

Do not use a bind mount like:

- `~/checkit_dev/db:/app/db`

### Run Tests

1. From the repository root, run `docker compose run --rm -e RAILS_ENV=test web bin/rails test`
2. For focused regression coverage around checklist timing and admin rendering, run:
   `docker compose run --rm -e RAILS_ENV=test web bin/rails test test/models/checklist_item_test.rb test/models/checklist_item_completion_test.rb test/integration/checklist_completion_flow_test.rb test/integration/admin_management_flow_test.rb`
3. Run targeted suites after changing specific areas:
   - checklist timing or scheduling logic:
     `docker compose run --rm -e RAILS_ENV=test web bin/rails test test/models/checklist_item_test.rb test/models/checklist_item_completion_test.rb`
   - user checklist rendering and completion flow:
     `docker compose run --rm -e RAILS_ENV=test web bin/rails test test/integration/checklist_completion_flow_test.rb`
   - admin checklist rendering, editing, and CSV flow:
     `docker compose run --rm -e RAILS_ENV=test web bin/rails test test/integration/admin_management_flow_test.rb`
4. When changing schema or time-related behavior, run migrations before testing:
   `docker compose run --rm web bin/rails db:migrate`
5. If a bug appears only during page rendering, add or update an integration or model regression test before closing the issue.

### Jenkins Container Build And Push

- The repository includes a `Jenkinsfile` that:
  1. checks out the SCM branch selected from `BRANCH_TAG`
  2. builds the application container from `Dockerfile`
  3. runs Brakeman SAST and writes the scanner output into `reports/` in the repository workspace
  4. bakes build metadata into the image for the shared application footer:
     - application name
     - application version when available
     - Git commit SHA
     - branch or environment
     - Jenkins build number
     - build timestamp
  5. tags the image with:
     - the short Git SHA
     - the sanitized environment tag
     - the explicit application version, when provided
  6. logs into the Docker registry with Jenkins-managed credentials
  7. pushes the generated tags to the configured repository

#### Jenkins Configuration

Create these Jenkins pipeline environment variables:

- `DOCKER_REGISTRY`
  - Docker Hub value for this repo: `docker.io`
  - Example for a private registry: `registry.example.com`
- `DOCKER_IMAGE_REPOSITORY`
  - Docker Hub value for this repo: `tjringrose01/checkit`
  - Example for a private registry: `platform/checkit`
- `DOCKER_CREDENTIALS_ID`
  - Jenkins credentials ID for the registry login
  - Default expected by the `Jenkinsfile`: `dockerhub_id`
- `BRANCH_TAG`
  - Required deployment environment selector
  - Allowed values: `dev`, `test`, `prod`
  - SCM checkout mapping:
    - `dev` -> `dev`
    - `test` -> `test`
    - `prod` -> `main`
- `APP_VERSION`
  - Optional release version such as `v0.3.0`
  - If set, Jenkins also tags and pushes `${DOCKER_IMAGE_REPOSITORY}:${APP_VERSION}`
  - If not set, the image still includes immutable Git SHA metadata and pushes the Git SHA tag
- `MAILGUN_DOMAIN`
  - Mailgun sending domain
  - Example: `mg.tjrcade.com`
- `MAILGUN_FROM_ADDRESS`
  - Sender address presented by the application
  - Example: `Mailgun Sandbox <postmaster@mg.tjrcade.com>`
- `MAILGUN_BASE_URL`
  - Optional Mailgun API base URL
  - Default: `https://api.mailgun.net`
  - Use `https://api.eu.mailgun.net` for EU-region Mailgun domains

#### Create The Jenkins Secret

1. In Jenkins, open `Manage Jenkins` > `Credentials`.
2. Choose the credential store and domain used by the pipeline.
3. Click `Add Credentials`.
4. Set `Kind` to `Username with password`.
5. Enter the Docker registry username.
6. Enter the Docker registry password or access token.
7. Set `ID` to the value used by `DOCKER_CREDENTIALS_ID`.
   Example: `dockerhub_id`
8. Save the credential.

For this repository, the credential should authenticate to the public Docker Hub repository:

- `tjringrose01/checkit`

#### Create The Mailgun Jenkins Secret

1. In Jenkins, open `Manage Jenkins` > `Credentials`.
2. Choose the credential store and domain used by the pipeline or deployment job.
3. Click `Add Credentials`.
4. Set `Kind` to `Secret text`.
5. Paste the Mailgun private API key as the secret value.
6. Set `ID` to a stable credential name.
   Example: `mailgun_api_key`
7. Save the credential.

Recommended Jenkins credential and variable mapping:

- Jenkins credential:
  - `mailgun_api_key` as `Secret text`
- Jenkins environment variables:
  - `MAILGUN_DOMAIN=mg.tjrcade.com`
  - `MAILGUN_FROM_ADDRESS=Mailgun Sandbox <postmaster@mg.tjrcade.com>`
  - `MAILGUN_BASE_URL=https://api.mailgun.net`

At deploy or runtime injection time, map the Jenkins credential value to:

- `MAILGUN_API_KEY`

Do not place the Mailgun API key directly in the `Jenkinsfile`.

#### Create The Jenkins Job

1. Create a `Pipeline` job or a multibranch pipeline pointed at this repository.
2. Ensure the Jenkins agent has Docker CLI access and permission to run `docker build`, `docker login`, and `docker push`.
3. Set the environment variables above in the job configuration or folder configuration.
   Recommended values for this repo:
   - `DOCKER_REGISTRY=docker.io`
   - `DOCKER_IMAGE_REPOSITORY=tjringrose01/checkit`
   - `DOCKER_CREDENTIALS_ID=dockerhub_id`
   - `BRANCH_TAG=dev` for the dev deployment job
   - `BRANCH_TAG=test` for the test deployment job
   - `BRANCH_TAG=prod` for the production deployment job
   - `APP_VERSION=v0.3.0` only for intentional release builds that should publish a semantic version tag
   - `MAILGUN_DOMAIN=mg.tjrcade.com`
   - `MAILGUN_FROM_ADDRESS=Mailgun Sandbox <postmaster@mg.tjrcade.com>`
   - `MAILGUN_BASE_URL=https://api.mailgun.net`
4. Run the pipeline.

If you create separate Jenkins jobs for each environment, set `BRANCH_TAG` per job:

- Development job: `BRANCH_TAG=dev`
- Test job: `BRANCH_TAG=test`
- Production job: `BRANCH_TAG=prod`

When `BRANCH_TAG=prod`, the pipeline checks out `main` from SCM and still tags the container as `prod`.

#### Resulting Image Tags

- `${DOCKER_REGISTRY}/${DOCKER_IMAGE_REPOSITORY}:${short_git_sha}`
- `${DOCKER_REGISTRY}/${DOCKER_IMAGE_REPOSITORY}:${BRANCH_TAG}`
- `${DOCKER_REGISTRY}/${DOCKER_IMAGE_REPOSITORY}:${APP_VERSION}` when `APP_VERSION` is set

#### Brakeman SAST Output

- The Jenkins pipeline runs `bundle exec brakeman` inside the built application image.
- The pipeline writes reports to:
  - `reports/brakeman-report.json`
  - `reports/brakeman-report.txt`
- The reports are stored in the checked-out repository workspace during the Jenkins build.
- The pipeline uses `--exit-on-warn`, so Brakeman warnings or higher-severity findings fail the build and prevent the image push stage from running.

#### Footer Metadata In Built Images

The Jenkins build bakes these values into the image so the running application can display them in the shared footer:

- `APP_NAME`
- `APP_VERSION` when provided
- `APP_GIT_SHA`
- `APP_BUILD_ENVIRONMENT`
- `APP_BUILD_NUMBER`
- `APP_BUILD_TIMESTAMP`

The resulting footer should make a running container traceable to:

- the application name
- the copyright notice
- the environment label
- the Jenkins build identifier such as `dev-99`
- the build timestamp rendered in the browser timezone

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
