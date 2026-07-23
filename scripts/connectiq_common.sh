#!/bin/bash

set -euo pipefail

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_LIB_DIR}/.." && pwd)"
APPS_DIR="${REPO_DIR}/apps"
SDK_BIN_DIR="${REPO_DIR}/connectiq-sdk-bin-local"
KEY_FILE="${REPO_DIR}/developer_key.der"
JAVA_BIN_DIR="/opt/homebrew/opt/openjdk@21/bin"
DEFAULT_DEVICE_ID="epix2"
DEFAULT_OPENMTP_APP="/Applications/OpenMTP.app"

require_file() {
  local path="$1"
  local label="$2"

  if [ ! -e "${path}" ]; then
    echo "Missing ${label}: ${path}" >&2
    exit 1
  fi
}

require_dir() {
  local path="$1"
  local label="$2"

  if [ ! -d "${path}" ]; then
    echo "Missing ${label}: ${path}" >&2
    exit 1
  fi
}

setup_java_path() {
  if [ -d "${JAVA_BIN_DIR}" ]; then
    export PATH="${JAVA_BIN_DIR}:$PATH"
  fi
}

list_apps() {
  if [ ! -d "${APPS_DIR}" ]; then
    return 0
  fi

  find "${APPS_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

print_available_apps() {
  local apps
  apps="$(list_apps)"

  echo "Available apps:"
  if [ -n "${apps}" ]; then
    while IFS= read -r app_name; do
      echo "  ${app_name}"
    done <<< "${apps}"
  else
    echo "  (none found)"
  fi
}

resolve_app_dir() {
  local app_name="$1"
  local app_dir="${APPS_DIR}/${app_name}"

  if [ ! -d "${app_dir}" ]; then
    echo "Unknown app: ${app_name}" >&2
    print_available_apps >&2
    exit 1
  fi

  printf '%s\n' "${app_dir}"
}

get_project_file() {
  local app_dir="$1"
  printf '%s\n' "${app_dir}/monkey.jungle"
}

get_output_file() {
  local app_name="$1"
  local app_dir="$2"
  printf '%s\n' "${app_dir}/build/${app_name}.prg"
}

find_watch_apps_dir() {
  local candidates=(
    "/Volumes/GARMIN/GARMIN/APPS"
    "/Volumes/GARMIN/Apps"
    "/Volumes/*/GARMIN/APPS"
    "/Volumes/*/Apps"
    "/Volumes/*/Internal Storage/GARMIN/APPS"
  )

  local candidate
  for pattern in "${candidates[@]}"; do
    for candidate in $pattern; do
      if [ -d "${candidate}" ]; then
        printf '%s\n' "${candidate}"
        return 0
      fi
    done
  done

  return 1
}

resolve_destination_dir() {
  local base_path="$1"

  if [ -d "${base_path}/GARMIN/APPS" ]; then
    printf '%s\n' "${base_path}/GARMIN/APPS"
    return 0
  fi

  if [ -d "${base_path}/APPS" ]; then
    printf '%s\n' "${base_path}/APPS"
    return 0
  fi

  if [ -d "${base_path}" ]; then
    printf '%s\n' "${base_path}"
    return 0
  fi

  return 1
}

find_openmtp_app() {
  local found_path=""

  if [ -d "${DEFAULT_OPENMTP_APP}" ]; then
    printf '%s\n' "${DEFAULT_OPENMTP_APP}"
    return 0
  fi

  found_path="$(mdfind 'kMDItemCFBundleIdentifier == "io.ganeshrvel.openmtp"' | head -n 1 || true)"
  if [ -n "${found_path}" ] && [ -d "${found_path}" ]; then
    printf '%s\n' "${found_path}"
    return 0
  fi

  return 1
}
