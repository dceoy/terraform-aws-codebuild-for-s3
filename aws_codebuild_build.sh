#!/usr/bin/env bash
#
# Wrapper command to start AWS CodeBuild build and wait for completion
#
# Usage:
#   aws_codebuild_build.sh [--verbose] [--timeout=<sec>] [<arg>...]
#   aws_codebuild_build.sh --version
#   aws_codebuild_build.sh -h|--help
#
# Options:
#   --verbose         Increase verbosity
#   --timeout=<sec>   Set timeout for waiting the result [default: 3600]
#   --interval=<sec>  Set interval for polling the build status [default: 10]
#   --version         Print version information and exit
#   -h, --help        Print this help text and exit
#
# Arguments:
#   <arg>             Arguments passed to aws codebuild start-build

set -euo pipefail

if [[ ${#} -ge 1 ]]; then
  for a in "${@}"; do
    [[ "${a}" = '--verbose' ]] && set -x && break
  done
fi

COMMAND_PATH="$(realpath "${0}")"
COMMAND_NAME="$(basename "${COMMAND_PATH}")"
COMMAND_VERSION='v0.0.1'
AWS_CODEBUILD_STARTBUILD_ARGS=()
TIMEOUT_SEC=3600
INTERVAL_SEC=10

function print_version {
  echo "${COMMAND_NAME}: ${COMMAND_VERSION}"
}

function print_usage {
  sed -ne '1,2d; /^#/!q; s/^#$/# /; s/^# //p;' "${COMMAND_PATH}"
}

function abort {
  {
    if [[ ${#} -eq 0 ]]; then
      cat -
    else
      echo "${COMMAND_NAME}: ${*}"
    fi
  } >&2
  exit 1
}

while [[ ${#} -ge 1 ]]; do
  case "${1}" in
    --verbose )
      shift 1
      ;;
    --timeout )
      TIMEOUT_SEC="${2}" && shift 2
      ;;
    --timeout=* )
      TIMEOUT_SEC="${1#*\=}" && shift 1
      ;;
    --interval )
      INTERVAL_SEC="${2}" && shift 2
      ;;
    --interval=* )
      INTERVAL_SEC="${1#*\=}" && shift 1
      ;;
    --version )
      print_version && exit 0
      ;;
    -h | --help )
      print_usage && exit 0
      ;;
    * )
      AWS_CODEBUILD_STARTBUILD_ARGS+=("${1}") && shift 1
      ;;
  esac
done

jq --version > /dev/null || abort "jq command not found"

COMMAND_TO_RUN=(aws codebuild start-build "${AWS_CODEBUILD_STARTBUILD_ARGS[@]}")
printf "Command: %s\n" "${COMMAND_TO_RUN[*]}"

START_DATETIME=$(date +%s)
STARTBUILD_RESPONSE=$("${COMMAND_TO_RUN[@]}")
printf "Response of start-build: %s\n" "$(jq -c '.' <<< "${STARTBUILD_RESPONSE}")"

BUILD_ID=$(jq -r '.build.id' <<< "${STARTBUILD_RESPONSE}")
if [[ -z "${BUILD_ID}" ]]; then
  abort "Failed to start the build"
else
  echo "Build ID: ${BUILD_ID}"
fi

BATCH_GET_BUILDS_RESPONSE=''
BUILD_STATUS=''
while [[ -z "${BUILD_STATUS}" ]] || [[ "${BUILD_STATUS}" = 'IN_PROGRESS' ]] || [[ $(($(date +%s) - START_DATETIME)) -le ${TIMEOUT_SEC} ]]; do
  sleep "${INTERVAL_SEC}"
  BATCH_GET_BUILDS_RESPONSE=$(aws codebuild batch-get-builds --ids "${BUILD_ID}")
  BUILD_STATUS=$(jq -r '.builds[0].buildStatus' <<< "${BATCH_GET_BUILDS_RESPONSE}")
done

printf "Response of batch-get-builds: %s\n" "$(jq -c '.' <<< "${BATCH_GET_BUILDS_RESPONSE}")"
printf "Build Status: %s\n" "${BUILD_STATUS}"

case "${BUILD_STATUS}" in
  'SUCCEEDED' )
    echo 'The build succeeded.'
    ;;
  'FAILED' )
    echo 'The build failed.' >&2
    exit 2
    ;;
  'FAULT' )
    echo 'The build faulted.' >&2
    exit 3
    ;;
  'TIMED_OUT' )
    echo 'The build timed out.' >&2
    exit 4
    ;;
  'STOPPED' )
    echo 'The build stopped.' >&2
    exit 5
    ;;
  'IN_PROGRESS' )
    echo "Waiting for the build timed out after ${TIMEOUT_SEC} seconds." >&2
    exit 6
    ;;
  * )
    echo 'Unknown build status.' >&2
    exit 7
    ;;
esac
