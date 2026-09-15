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

Required env vars (see `.env.example`): `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`. `SECRET_KEY_BASE` is optional — if unset, JWT signing falls back to `Rails.application.secret_key_base` (Rails credentials).

## Architecture

All product code lives under the `Api::V1` namespace (`app/controllers/api/v1/**`); there is no non-API surface. `app/controllers/api/v1/application_controller.rb` is the base for every controller:

- `before_action :authenticate_user!` is on by default — auth is opt-out (`skip_before_action`), not opt-in. See `Auth::AuthenticationController` for the only controller that skips it (`register`/`login`).
- Auth is JWT with a revocation denylist. The actual encode/decode lives in `Api::V1::JsonWebToken` (`lib/api/v1/json_web_token.rb`), not in the controller: `.encode(user)`/`.decode(token)` build/read `{ sub: user.id, uuid: user.uuid, jti: ..., exp: ... }`, signed with `.secret` (`ENV["SECRET_KEY_BASE"]`, falling back to `Rails.application.secret_key_base`/credentials if unset), and `.decode` returns `nil` for a revoked or malformed token. `ApplicationController#issue_token`/`#decoded_token` are thin wrappers around it (`decoded_token` also pulls the token out of the `Authorization` header and memoizes it per-request). `current_user` is resolved from `decoded_token["sub"]`; there are no sessions. `POST /auth/logout` inserts the token's `jti` into `RevokedToken`, which is what `.decode` checks to invalidate a token before it naturally expires. Run `rails revoked_tokens:purge_expired` periodically (e.g. via cron) to keep that table from growing unbounded — nothing does this automatically yet.
- Centralized `rescue_from` handlers translate exceptions to the standard envelope (`ActionController::ParameterMissing` → 400, `ActiveRecord::RecordNotFound` → 404, `Posts::FeedQuery::InvalidPagination` → 400).

**Every JSON response goes through `Api::V1::Response`** (`lib/api/v1/response.rb`), which wraps output as `{ data, errors, meta }`. Never `render json:` a bare model/hash in a controller — build a `Response.success(data:, meta:)` or `Response.error(messages, meta:)` instead, so the envelope stays consistent across endpoints.

**Authorization is implemented by scoping through Active Record, not by a dedicated policy layer** (no Pundit/CanCan). Two scopes matter: `current_user.posts`/`current_user.comments`/`current_user.likes` (ownership — used for `update`/`destroy`) and `Post.visible_to(current_user)` (read access respecting `visibility`: own posts, plus other users' `published` posts that are `public`, or `followers`-visible from someone you follow — used for `show` and for `create` on comments/likes so you can interact with posts you don't own). When adding a new action, decide explicitly which of the two you need — `find` alone doesn't check anything; the scope it's called on is what enforces access.

Post media validations (`Post::MAX_MEDIA_FILES`, `MAX_MEDIA_SIZE`, `ALLOWED_MEDIA_TYPES`) and URL serialization live in `app/models/post.rb`. `Post#as_json` calls `rails_blob_url` from the model (no request context), so it needs `ActiveStorage::Current.url_options` explicitly — `ApplicationController` sets that via Rails' `ActiveStorage::SetCurrent` concern per-request; specs set a default in `spec/rails_helper.rb`. Any controller action that serializes posts must eager-load attachments with `.with_attached_media` or it N+1s per post.

Query logic that's more than a simple scope belongs in `app/queries/` as a PORO (see `Posts::FeedQuery`), not inline in the controller — it takes the actor + pagination params and returns `{ posts:, meta: }`, and raises its own typed error (`InvalidPagination`) that the base controller rescues.

Serialization is ad-hoc `as_json` with `include:`, not a serializer layer: `User#as_json` always excludes `password_digest` and adds `full_name`; posts/comments/likes serialize nested associations directly in the controller action (e.g. `@post.as_json(include: { comments: { include: :user }, likes: { include: :user } })`). Follow this pattern rather than introducing a new serialization approach for one endpoint.

Users are addressed by `uuid` in routes/params (`UsersController#set_user`), not by numeric `id` — posts/comments/likes are still addressed by numeric `id`. Don't mix these up when adding routes.

`User` and `Post` use the `paranoia` gem (`acts_as_paranoid`) for soft delete: `#destroy` sets `deleted_at` instead of removing the row, every normal query (including through associations, e.g. `user.posts`) automatically excludes soft-deleted records, and `#really_destroy!` is the actual hard delete. Use `.with_deleted`/`.only_deleted` to see soft-deleted records, and `#restore`/`#restore!` to undo. `Comment` and `Like` are deliberately **not** paranoid — and deliberately have no `dependent:` option on the `has_many` side (see `Post`/`User`), because a non-paranoid child under `dependent: :destroy` gets *really* deleted when the paranoid parent's (soft) `destroy` runs the standard Rails callback chain. Destroying a `User` cascades to soft-delete their `posts` (also paranoid, so it just works via `dependent: :destroy`), but leaves their comments/likes and the target rows of `Follower`/`RevokedToken` alone per their own association options. The unique index on `lower(email)` is a **partial** index (`WHERE deleted_at IS NULL`, see the `AddDeletedAtToUsers` migration) so a deactivated account's email can be reused — paranoia patches `ActiveRecord::Validations::UniquenessValidator` to ignore soft-deleted rows for any paranoid model automatically, but that patch is Ruby-level only, so the DB index needed the same treatment by hand.

`Post.with_counts` (in the model) does a `left_joins` + `COUNT(DISTINCT)` + `GROUP BY` to attach `comments_count`/`likes_count` — reuse this scope rather than adding N+1 counting queries; it's combined with `.includes(comments: :user, likes: :user)` in the feed/index actions to avoid N+1 on the nested serialization above.

Request specs (`spec/requests/api/v1/**`) are the primary test layer and exercise the full auth/response-envelope stack; use `auth_headers(user)` (defined in `spec/rails_helper.rb`) to get a valid JWT header for a fixture user. Fixtures live in `spec/fixtures/*.yml`, loaded globally (`config.global_fixtures = :all`). The legacy `test/` directory (Minitest, Rails default scaffold) is unused — this project's tests are RSpec under `spec/`.
