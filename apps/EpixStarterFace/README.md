# Epix Starter Face

Separate Garmin Connect IQ watch-face app inside the shared multi-app workspace.

## App Layout

- `manifest.xml`: app metadata and target device selection
- `monkey.jungle`: build configuration
- `source/`: Monkey C app and watch-face view code
- `resources/`: layouts, strings, and drawables
- `build/`: generated build output for this app

## Recommended Commands

From the repo root:

```bash
./build_app.sh EpixStarterFace
./run_simulator.sh EpixStarterFace
./deploy_to_watch.sh EpixStarterFace --openmtp
```

From this app folder:

```bash
./build_only.sh
./run_simulator.sh
./deploy_to_watch.sh --openmtp
```

The local wrapper scripts forward to the shared repo-level scripts.

## Current Target

- Product: `epix2`
- App type: `watchface`
- Minimum API: `5.1.0`
