// Base URL of the FastAPI backend.
// - Web / Windows desktop / iOS simulator: `http://localhost:8000` works as-is.
// - Android emulator: the emulator can't see the host as "localhost" — use
//   `http://10.0.2.2:8000` instead (10.0.2.2 is the emulator's alias for
//   the host machine).
// - A physical phone/tablet: use your computer's LAN IP, e.g.
//   `http://192.168.1.23:8000`, and make sure the backend is reachable on
//   that network (see the backend README's CORS_ORIGINS setting too).

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

const int kDefaultPageSize = 10;


