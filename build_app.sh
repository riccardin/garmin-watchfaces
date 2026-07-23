#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/scripts/connectiq_common.sh"

print_usage() {
  echo "Usage:"
  echo "  ./build_app.sh <app-name> [--device <device-id>]"
  echo "  ./build_app.sh --list"
}

APP_NAME=""
DEVICE_ID="${DEFAULT_DEVICE_ID}"

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
PROJECT_FILE="$(get_project_file "${APP_DIR}")"
OUTPUT_FILE="$(get_output_file "${APP_NAME}" "${APP_DIR}")"
MONKEYC="${SDK_BIN_DIR}/monkeyc"

setup_java_path
require_file "${MONKEYC}" "Monkey C compiler"
require_file "${KEY_FILE}" "developer key"
require_file "${PROJECT_FILE}" "project jungle file"

mkdir -p "${APP_DIR}/build"

echo "Building ${APP_NAME} for ${DEVICE_ID}..."
"${MONKEYC}" \
  -f "${PROJECT_FILE}" \
  -d "${DEVICE_ID}" \
  -y "${KEY_FILE}" \
  -o "${OUTPUT_FILE}" \
  -w

echo "Build complete: ${OUTPUT_FILE}"
