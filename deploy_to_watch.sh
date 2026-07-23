#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/scripts/connectiq_common.sh"

print_usage() {
  echo "Usage:"
  echo "  ./deploy_to_watch.sh <app-name> [destination-path] [--device <device-id>] [--openmtp]"
  echo "  ./deploy_to_watch.sh --list"
}

print_manual_copy_help() {
  local output_file="$1"

  echo "Copy this file into GARMIN/APPS on the watch:"
  echo "  ${output_file}"
  echo
  echo "If you know the mounted destination path, run:"
  echo "  ./deploy_to_watch.sh ${APP_NAME} /path/to/GARMIN/APPS"
}

APP_NAME=""
DEVICE_ID="${DEFAULT_DEVICE_ID}"
MANUAL_DESTINATION=""
OPEN_MTP_ONLY=false

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
    --openmtp)
      OPEN_MTP_ONLY=true
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
      elif [ -z "${MANUAL_DESTINATION}" ]; then
        MANUAL_DESTINATION="$1"
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

require_file "${BUILD_SCRIPT}" "build script"

"${BUILD_SCRIPT}" "${APP_NAME}" --device "${DEVICE_ID}"
require_file "${OUTPUT_FILE}" "built PRG file"

if [ "${OPEN_MTP_ONLY}" = true ]; then
  print_manual_copy_help "${OUTPUT_FILE}"

  if OPENMTP_APP="$(find_openmtp_app)"; then
    echo
    echo "Opening OpenMTP..."
    open -a "${OPENMTP_APP}"
    exit 0
  fi

  echo
  echo "OpenMTP could not be found." >&2
  echo "Install it with: brew install --cask openmtp" >&2
  exit 1
fi

if [ -n "${MANUAL_DESTINATION}" ]; then
  if WATCH_APPS_DIR="$(resolve_destination_dir "${MANUAL_DESTINATION}")"; then
    echo "Using manual destination: ${WATCH_APPS_DIR}"
    cp "${OUTPUT_FILE}" "${WATCH_APPS_DIR}/"
    echo "Copied ${OUTPUT_FILE} to ${WATCH_APPS_DIR}"
    echo "Safely disconnect the watch, then select the watch face on the device."
    exit 0
  fi

  echo "The manual destination does not exist or is not a valid Garmin APPS path:" >&2
  echo "  ${MANUAL_DESTINATION}" >&2
  exit 1
fi

if WATCH_APPS_DIR="$(find_watch_apps_dir)"; then
  echo "Found Garmin watch storage at: ${WATCH_APPS_DIR}"
  cp "${OUTPUT_FILE}" "${WATCH_APPS_DIR}/"
  echo "Copied ${OUTPUT_FILE} to ${WATCH_APPS_DIR}"
  echo "Safely disconnect the watch, then select the watch face on the device."
  exit 0
fi

echo "Could not find a mounted Garmin watch storage path." >&2
echo "If you are on macOS, your watch may require OpenMTP for file transfer." >&2
print_manual_copy_help "${OUTPUT_FILE}" >&2

if OPENMTP_APP="$(find_openmtp_app)"; then
  echo "Opening OpenMTP..." >&2
  open -a "${OPENMTP_APP}"
else
  echo "OpenMTP could not be found." >&2
  echo "Install it with: brew install --cask openmtp" >&2
fi

exit 1
