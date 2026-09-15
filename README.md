# Social API

## Table of Contents

- [Description](#description)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Class Diagram](#class-diagram)
- [Technologies Used](#technologies-used)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [API Documentation](#api-documentation)

## Description

This Social API is developed using Ruby on Rails 7 and its primary goal is to allow users to register, follow other users, and manage their posts.

## Features

- **User Registration**: Users can securely register and authenticate on the platform.
- **User Following**: Users can follow other users and receive updates on their activities.
- **Content Posting**: Users can create, edit, and delete posts that can include text, images, and multimedia.
- **User Authentication:** User authentication is done securely, ensuring that only authorized users can access your personal data.

## System Architecture

This diagram illustrates how our system operates and how clients interact with our services through Ruby on Rails:

![System Architecture](doc/Social%20App-architecture.drawio.png)

The architecture demonstrates the flow of data and requests from clients to our Rails-based services. It highlights the essential components that ensure a smooth interaction experience.

## Class Diagram

Here is the class diagram illustrating models and their relationships:

![Class Diagram](doc/Social%20App-social-api.drawio.png)

## Technologies Used

This API employs a variety of technologies and tools, including:

- Ruby 3.2.1
- Ruby on Rails 7
- PostgreSQL as the relational database.
- [List any other technologies and gems you might be using in your project]

## Prerequisites

Before starting to use this API, make sure you have the following:

- Ruby 3.2.1 installed on your system.
- Ruby on Rails 7 installed.
- PostgreSQL installed and configured for the database.
- ...

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

## Usage

Our API follows the REST (Representational State Transfer) architectural style, which is based on simple principles for accessing and manipulating resources using standard HTTP methods. Here's an overview of how to use it:

- **HTTP Methods**: Use standard HTTP methods to interact with the API:
  - `GET`: To retrieve information.
  - `POST`: To create new resources.
  - `PUT` or `PATCH`: To update existing resources.
  - `DELETE`: To delete resources.

- **Authentication**: Some actions may require authentication. You can use authentication tokens, API keys, or any other mechanism provided by the API.

- **Response Format**: The API returns data in a common format such as JSON. You should parse the responses to obtain the information you need.

## API Documentation

The full documentation for every endpoint (requests, parameters, and example responses) is available as a Postman collection: [`doc/Social API.postman_collection.json`](doc/Social%20API.postman_collection.json). Import it into Postman to explore and try out the API.

If you're a developer interested in using our API or have any questions, please don't hesitate to get in touch:

- Email: [mformento8@gmail.com](mailto:mformento8@gmail.com)
