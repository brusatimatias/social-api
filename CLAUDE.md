# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Description

Ruby on Rails 7 API-only social app: users register, follow each other, post content, and comment/like posts.

## Commands

```bash
bundle install                                   # install gems
rails db:create db:migrate                       # set up the database (env vars from .env)
rails server                                      # run the app (localhost:3000)

bundle exec rspec                                 # run the full test suite
bundle exec rspec spec/requests/api/v1/posts_spec.rb            # single file
bundle exec rspec spec/requests/api/v1/posts_spec.rb:42         # single example by line

bundle exec rubocop --config .rubocop.yml         # lint (matches CI)
bundle exec rubocop -A                            # autocorrect
```

CI (`.github/workflows/ci.yml`) runs `rspec` and `rubocop` as separate jobs against Postgres 15 on every push/PR — always run both locally before considering a change done.

Required env vars (see `.env.example`): `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`.

## Architecture

All product code lives under the `Api::V1` namespace (`app/controllers/api/v1/**`); there is no non-API surface. `app/controllers/api/v1/application_controller.rb` is the base for every controller:

- `before_action :authenticate_user!` is on by default — auth is opt-out (`skip_before_action`), not opt-in. See `Auth::AuthenticationController` for the only controller that skips it (`register`/`login`).
- Auth is JWT with a revocation denylist: `issue_token`/`decoded_token` encode/decode `{ sub: user.id, jti: ..., exp: ... }` with `Rails.application.secret_key_base`. `current_user` is resolved from the `Authorization: Bearer <token>` header per-request; there are no sessions. `POST /auth/logout` inserts the token's `jti` into `RevokedToken`; `decoded_token` treats a token as invalid if its `jti` is in that table, so a token can be revoked before it naturally expires. Run `rails revoked_tokens:purge_expired` periodically (e.g. via cron) to keep that table from growing unbounded — nothing does this automatically yet.
- Centralized `rescue_from` handlers translate exceptions to the standard envelope (`ActionController::ParameterMissing` → 400, `ActiveRecord::RecordNotFound` → 404, `Posts::FeedQuery::InvalidPagination` → 400).

**Every JSON response goes through `Api::V1::Response`** (`lib/api/v1/response.rb`), which wraps output as `{ data, errors, meta }`. Never `render json:` a bare model/hash in a controller — build a `Response.success(data:, meta:)` or `Response.error(messages, meta:)` instead, so the envelope stays consistent across endpoints.

**Authorization is currently implemented by scoping through `current_user`, not by an authorization layer.** Controllers look up records via `current_user.posts.find(...)`, `current_user.posts.find(params[:post_id])`, etc. This means a user can only see/act on their own posts and their nested comments/likes — the `visibility` enum on `Post` (`public`/`followers`/`private`) is not yet enforced for reads of other users' posts. Keep this pattern in mind when changing access: there is no Pundit/CanCan-style policy object yet, so any change to who-can-access-what happens by changing these scoping calls (or introducing a policy layer) — don't assume `find` alone is checking ownership.

Query logic that's more than a simple scope belongs in `app/queries/` as a PORO (see `Posts::FeedQuery`), not inline in the controller — it takes the actor + pagination params and returns `{ posts:, meta: }`, and raises its own typed error (`InvalidPagination`) that the base controller rescues.

Serialization is ad-hoc `as_json` with `include:`, not a serializer layer: `User#as_json` always excludes `password_digest` and adds `full_name`; posts/comments/likes serialize nested associations directly in the controller action (e.g. `@post.as_json(include: { comments: { include: :user }, likes: { include: :user } })`). Follow this pattern rather than introducing a new serialization approach for one endpoint.

Users are addressed by `uuid` in routes/params (`UsersController#set_user`), not by numeric `id` — posts/comments/likes are still addressed by numeric `id`. Don't mix these up when adding routes.

`Post.with_counts` (in the model) does a `left_joins` + `COUNT(DISTINCT)` + `GROUP BY` to attach `comments_count`/`likes_count` — reuse this scope rather than adding N+1 counting queries; it's combined with `.includes(comments: :user, likes: :user)` in the feed/index actions to avoid N+1 on the nested serialization above.

Request specs (`spec/requests/api/v1/**`) are the primary test layer and exercise the full auth/response-envelope stack; use `auth_headers(user)` (defined in `spec/rails_helper.rb`) to get a valid JWT header for a fixture user. Fixtures live in `spec/fixtures/*.yml`, loaded globally (`config.global_fixtures = :all`). The legacy `test/` directory (Minitest, Rails default scaffold) is unused — this project's tests are RSpec under `spec/`.
