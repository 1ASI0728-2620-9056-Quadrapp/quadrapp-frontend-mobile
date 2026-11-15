# Quadrapp Mobile

Driver app of Quadrapp (Flutter).

## Run with mocks or against the backend

The app reads its configuration from `--dart-define` (`lib/app/config/app_config.dart`):

| Define | Default | Meaning |
| --- | --- | --- |
| `USE_MOCKS` | `true` in debug, `false` in release | `true` uses the simulated world (`assets/mocks/seed.json`); `false` calls the backend API. |
| `API_BASE_URL` | `http://10.0.2.2:8080/api/v1` | Base URL of the REST API, **including `/api/v1`**. The STOMP endpoint is derived from it: `wss://<host>/ws` (or `ws://` for `http`). |

Against the deployed API:

```sh
flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=https://api.<domain>/api/v1
flutter build apk --release --dart-define=API_BASE_URL=https://api.<domain>/api/v1
```

Against a backend running locally (Android emulator):

```sh
flutter run --dart-define=USE_MOCKS=false
```

## What comes from the backend

| Flow | Endpoints |
| --- | --- |
| Sign-in with a one-time code | `POST /iam/auth/request-otp`, `/sign-in`, `/refresh` (the refresh token rotates), `/sign-out`; `GET /iam/institutions/{id}` for the institution name |
| Parking lots and layout | `GET /parking-lots`, `/parking-lots/{id}`, `/parking-lots/{id}/zones`, `/zones/{id}/levels`, `/levels/{id}/spaces` |
| Occupancy | `GET /parking-lots/{id}/occupancy`, `/zones/{id}/occupancy`, `/parking-lots/{id}/spaces/status` (state of each space for the space map and level counts); live updates on STOMP `/topic/parking-lots/{id}/occupancy` (the JWT goes in the `CONNECT` frame) |
| Forecasts and arrival advice | `GET /parking-lots/{id}/forecasts` (latest run, one per horizon), `POST /arrival-advices` |

Not provided by the backend yet, so the real build shows them as unavailable:

- The next availability estimate ("no estimate").
- Alert subscriptions (`/notification-subscriptions`), notification preferences (`/notification-preferences`), device push tokens (`/device-tokens`) and the operator shift view (`/console/overview`) still call routes the backend does not have, so they show an error in the real build.
