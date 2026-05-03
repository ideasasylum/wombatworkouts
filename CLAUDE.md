# Wombat Workouts

## Local dev URL

When the dev server is running under Conductor, the active URL is written to `.context/dev-url.txt`. Read that file to find the host:port for browser-based testing (it uses `https://` and a self-signed mkcert cert).

If the file is missing, the server is not running — start it with `mise run dev` (or via Conductor's run script).
