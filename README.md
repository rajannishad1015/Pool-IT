# SmartPool Monorepo

Welcome to the SmartPool project. This project is structured as a monorepo containing multiple Flutter applications.

## Project Structure

- **`apps/user_app`**: The primary application for passengers/users to find and book rides. (Previously the root project)
- **`apps/driver_app`**: Dedicated application for drivers to offer rides and manage their trips.
- **`apps/admin_app`**: Internal dashboard for managing the platform, users, and disputes.

## Getting Started

To run any of the apps, navigate to its respective directory:

```bash
cd apps/user_app
flutter run
```

```bash
cd apps/driver_app
flutter run
```

```bash
cd apps/admin_app
flutter run
```

## Shared Logic
Shared logic (services, models, themes) should eventually be moved to a `packages/` directory to avoid duplication.
