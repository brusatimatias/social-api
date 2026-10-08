# Social API

## Table of Contents

- [Description](#description)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Class Diagram](#class-diagram)
- [Technologies Used](#technologies-used)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Maintenance Tasks](#maintenance-tasks)
- [Running Tests](#running-tests)
- [Usage](#usage)
- [API Documentation](#api-documentation)

## Description

This Social API is developed using Ruby on Rails 7 and its primary goal is to allow users to register, follow other users, publish posts, and comment on and like posts. User profiles are synced to a companion service, `social-messaging-api`.

## Features

- **User Registration and Authentication**: Users register and log in to get a JWT. Logging out revokes the token right away. Users can update their profile (including an avatar) or deactivate their account.
- **User Following**: Users can follow and unfollow other users, and list anyone's followers and following.
- **User Search**: Users can search for other users by name, last name or email, with paginated results.
- **Content Posting**: Users can create, edit and delete posts with text and media attachments. A post can be `draft`, `published` or `archived`.
- **Post Visibility**: Each post is `public`, `followers` (visible only to people who follow the author) or `private` (visible only to the author).
- **Comments and Likes**: Users can comment on and like any post they're allowed to see.
- **Feed**: A paginated feed shows the newest published posts the user can see, with comment and like counts.
- **Messaging Sync**: User profiles are kept in sync with `social-messaging-api` automatically, with a rake task to backfill them (see [Maintenance Tasks](#maintenance-tasks)).

## System Architecture

This diagram illustrates how our system operates and how clients interact with our services through Ruby on Rails:

![System Architecture](doc/Social%20App-architecture.drawio%20v2.png)

The architecture demonstrates the flow of data and requests from clients to our Rails-based services. It highlights the essential components that ensure a smooth interaction experience.

## Class Diagram

Here is the class diagram illustrating models and their relationships:

![Class Diagram](doc/Social%20App-social-api.drawio.png)

## Technologies Used

This API employs a variety of technologies and tools, including:

- Ruby 3.2.1
- Ruby on Rails 7
- PostgreSQL as the relational database.
- JWT (`jwt` gem) for stateless authentication, with a revocation denylist for logout.
- `paranoia` for soft-deleting users and posts.
- Active Storage for post media and user avatars.
- Faraday as the HTTP client to sync users to `social-messaging-api`.
- RSpec and RuboCop for tests and linting (run in CI via GitHub Actions).

## Prerequisites

Before starting to use this API, make sure you have the following:

- Ruby 3.2.1 installed on your system.
- Ruby on Rails 7 installed.
- PostgreSQL installed and configured for the database.
- A running instance of `social-messaging-api` if you want user changes synced there (optional for local development).

## Installation

Follow these steps to get started with this API:

1. **Clone this repository:**

   ```bash
   git clone git@github.com:brusatimatias/social-api.git
   cd social-api
   ```

2. **Install the required gems:**

   ```bash
   bundle install
   ```

   This will install all the necessary Ruby gems specified in your project's `Gemfile`. If you encounter any issues during the installation, make sure you have Ruby and Bundler installed correctly.

3. **Configure the database using environment variables:**

   Set the following environment variables in your `.env` file located in the root of your project:

   ```env
   POSTGRES_USER=yourusername
   POSTGRES_PASSWORD=yourpassword
   ```

   Replace `yourusername` and `yourpassword` with your actual database username and password.

   See `.env.example` for the full list of environment variables, including `SECRET_KEY_BASE` (JWT signing), `CORS_ORIGINS`, and `SOCIAL_MESSAGING_API_URL` (base URL of `social-messaging-api`, used to sync users — that app's `SECRET_KEY` must match this app's `SECRET_KEY_BASE`).

4. **Create the database and run migrations:**

   ```bash
   rails db:create
   rails db:migrate
   ```

   This will set up the database using the environment variables defined in your `database.yml` file.

5. **Start the application:**

   ```bash
   rails server
   ```

   Your API should now be running locally at `http://localhost:3000`. You can access it using a web browser or make API requests using tools like `curl` or Postman.

## Maintenance Tasks

- **Purge expired revoked tokens.** Logging out stores the token's `jti` in a denylist table that nothing cleans up automatically. Run this periodically (e.g. via cron) to delete entries whose JWT has already expired:

  ```bash
  rails revoked_tokens:purge_expired
  ```

- **Backfill users to `social-messaging-api`.** New and updated users are synced automatically through a background job, but users that existed before that integration (or that were changed while `social-messaging-api` was unreachable and exhausted their retries) need a one-off backfill:

  ```bash
  rails social_messaging_api:sync_users
  ```

  It upserts every active (not soft-deleted) user, so it's safe to re-run. It calls the API synchronously, without retries, and stops at the first error — fix the cause and run it again. It does not remove deactivated users from `social-messaging-api`.

## Running Tests

```bash
bundle exec rspec                          # full test suite
bundle exec rubocop --config .rubocop.yml  # lint
```

Both run in CI on every push and pull request.

## Usage

The API is REST-style JSON over HTTP. Every endpoint lives under `/api/v1` (e.g. `http://localhost:3000/api/v1/feed`).

### Authentication

Authentication uses JWTs. Register or log in to get a token:

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"auth": {"email": "jane@example.com", "password": "secret123"}}'
```

The response includes `data.token`. Send it on every other request as a Bearer token:

```bash
curl http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer <token>"
```

- Only `POST /auth/register` and `POST /auth/login` work without a token. Every other endpoint returns `401 Unauthorized` if the token is missing, invalid, expired or revoked.
- Tokens expire after 24 hours.
- `DELETE /auth/logout` revokes the current token right away.
- `DELETE /auth/me` deactivates the account (soft delete). After that, the same email can be used to register again.

### Response format

Every response, whether it succeeds or fails, has the same structure:

```json
{
  "data": { },
  "errors": [],
  "meta": {}
}
```

- On success, `data` holds the result and `errors` is empty.
- On failure, `data` is `null` and `errors` lists messages. The HTTP status tells you the kind of failure: `400` for missing params or invalid pagination, `401` unauthorized, `404` not found, `422` validation errors.

### Pagination

Paginated endpoints (`GET /feed`, `GET /users/search`) accept `page` (default `1`) and `per_page` (default `20`, max `50`). Pagination details come in `meta`:

```json
"meta": { "current_page": 1, "per_page": 20, "total_pages": 3, "total_count": 42 }
```

### Identifiers

- Users are addressed by their `uuid` (e.g. `POST /users/:uuid/follow`).
- Posts, comments and likes are addressed by numeric `id` (e.g. `POST /posts/:post_id/comments`).

## API Documentation

The full documentation for every endpoint (requests, parameters, and example responses) is available as a Postman collection: [`doc/Social API.postman_collection.json`](doc/Social%20API.postman_collection.json). Import it into Postman to explore and try out the API.

If you're a developer interested in using our API or have any questions, please don't hesitate to get in touch:

- Email: [mformento8@gmail.com](mailto:mformento8@gmail.com)
