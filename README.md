# Garmin Watch Faces

Multi-app Garmin Connect IQ workspace for separate watch-face projects in one repo.

## Repository Layout

- `apps/`: one folder per installable watch-face app
- `apps/<app-name>/manifest.xml`: app metadata and target device selection
- `apps/<app-name>/monkey.jungle`: build configuration for that app
- `apps/<app-name>/source/`: Monkey C app and view code
- `apps/<app-name>/resources/`: layouts, strings, and drawables
- `apps/<app-name>/build/`: generated build output for that app
- `scripts/connectiq_common.sh`: shared script helpers
- `build_app.sh`: build any app in `apps/`
- `run_simulator.sh`: build and push any app to the simulator
- `deploy_to_watch.sh`: build and copy any app to a real watch

## Current Apps

- `EpixStarterFace`
- `SpiderManFace`

List the available apps at any time with:

```bash
./build_app.sh --list
```

## Prerequisites

- Garmin Connect IQ SDK installed
- Monkey C VS Code extension installed
- Java available at:
  - `/opt/homebrew/opt/openjdk@21/bin`
- Developer key available at:
  - `/Users/rick.magana/Documents/Apps/garmin/developer_key.der`

This workspace currently uses a local SDK bin copy because the installed SDK path under `Application Support` caused build issues with Garmin's `default.jungle` handling.

- Local SDK bin path:
  - `/Users/rick.magana/Documents/Apps/garmin/connectiq-sdk-bin-local`

## Build

Build a specific watch face:

```bash
./build_app.sh EpixStarterFace
```

Choose a different simulator/watch target if needed:

```bash
./build_app.sh EpixStarterFace --device epix2
```

Expected output file:

- `/Users/rick.magana/Documents/Apps/garmin/apps/EpixStarterFace/build/EpixStarterFace.prg`

## Start Simulator

Launch the Connect IQ simulator:

```bash
export PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH
/Users/rick.magana/Documents/Apps/garmin/connectiq-sdk-bin-local/connectiq
```

## Push To Simulator

Build and push a specific app:

```bash
./run_simulator.sh EpixStarterFace
```

## Deploy To Real Watch

Build and copy a specific app to a connected Garmin watch when the watch storage is available:

```bash
./deploy_to_watch.sh EpixStarterFace
```

Manual destination example:

```bash
./deploy_to_watch.sh EpixStarterFace /path/to/GARMIN/APPS
```

Open OpenMTP and print the exact file to drag:

```bash
./deploy_to_watch.sh EpixStarterFace --openmtp
```

You can also pass a parent Garmin storage path and the script will try:

- `/path/to/GARMIN/APPS`
- `/path/to/APPS`
- `/path/to/` as-is

## App-Local Convenience Scripts

Each app can keep thin wrapper scripts for convenience. For example:

```bash
./apps/EpixStarterFace/build_only.sh
./apps/EpixStarterFace/run_simulator.sh
./apps/EpixStarterFace/deploy_to_watch.sh --openmtp
```

Those wrappers call the shared repo-level scripts using the app folder name.

## VS Code Notes

If you prefer using the Monkey C extension in VS Code:

- Open `/Users/rick.magana/Documents/Apps/garmin`
- Work inside the app you want under `apps/<app-name>`
- Set the developer key path to:
  - `/Users/rick.magana/Documents/Apps/garmin/developer_key.der`
- Use the Monkey C commands with the app's `monkey.jungle`
