#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/scripts/connectiq_common.sh"

print_usage() {
  echo "Usage:"
  echo "  ./run_simulator.sh <app-name> [--device <device-id>]"
  echo "  ./run_simulator.sh --list"
}

APP_NAME=""
DEVICE_ID="${DEFAULT_DEVICE_ID}"
PUSH_ATTEMPTS=10
PUSH_WAIT_SECONDS=2

while [ "$#" -gt 0 ]; do
  case "$1" in
    --device)
      shift
      if [ "$#" -eq 0 ]; then
        echo "Missing value for --device" >&2
        exit 1
      fi
      DEVICE_ID="$1"
      ;;
    --list)
      print_available_apps
      exit 0
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      if [ -z "${APP_NAME}" ]; then
        APP_NAME="$1"
      else
        echo "Unexpected argument: $1" >&2
        print_usage >&2
        exit 1
      fi
      ;;
  esac
  shift
done

if [ -z "${APP_NAME}" ]; then
  print_usage >&2
  exit 1
fi

APP_DIR="$(resolve_app_dir "${APP_NAME}")"
OUTPUT_FILE="$(get_output_file "${APP_NAME}" "${APP_DIR}")"
BUILD_SCRIPT="${SCRIPT_DIR}/build_app.sh"
MONKEYDO="${SDK_BIN_DIR}/monkeydo"
SIMULATOR="${SDK_BIN_DIR}/connectiq"
SIMULATOR_LOG="/tmp/${APP_NAME}-simulator.log"

setup_java_path
require_file "${MONKEYDO}" "simulator push tool"
require_file "${SIMULATOR}" "Connect IQ simulator launcher"
require_file "${BUILD_SCRIPT}" "build script"

"${BUILD_SCRIPT}" "${APP_NAME}" --device "${DEVICE_ID}"
require_file "${OUTPUT_FILE}" "built PRG file"

if ! pgrep -f "${SIMULATOR}" >/dev/null 2>&1; then
  echo "Starting Connect IQ simulator..."
  nohup "${SIMULATOR}" >"${SIMULATOR_LOG}" 2>&1 &
  sleep 6
else
  echo "Connect IQ simulator is already running."
fi

echo "Pushing ${APP_NAME} to simulator..."
for ((attempt=1; attempt<=PUSH_ATTEMPTS; attempt+=1)); do
  if "${MONKEYDO}" "${OUTPUT_FILE}" "${DEVICE_ID}"; then
    echo "Done."
    exit 0
  fi

  if [ "${attempt}" -lt "${PUSH_ATTEMPTS}" ]; then
    echo "Simulator not ready yet. Retrying (${attempt}/${PUSH_ATTEMPTS})..."
    sleep "${PUSH_WAIT_SECONDS}"
  fi
done

echo "Failed to push to simulator after ${PUSH_ATTEMPTS} attempts." >&2
echo "If the simulator UI is still opening, wait a few seconds and run the script again." >&2
exit 1
