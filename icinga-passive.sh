#!/bin/bash

AUTHOR="Paul Bargewell <paul.bargewell@opusvl.com>"
COPYRIGHT="Copyright 2021, Opus Vision Limited T/A OpusVL"
LICENSE="SPDX-License-Identifier: AGPL-3.0-or-later"
PROGNAME=$(basename $0)
RELEASE="Revision 1.0.0"

# Expect varoables from .env
# ICINGA_HOST=
# ICINGA_PORT=
# ICINGA_USER=
# ICINGA_PASSWORD=

if [ -f '.env' ]; then
    source .env
fi

print_usage() {
  echo ""
  echo "$PROGNAME $RELEASE - Icinga2 Passive Checks"
  echo ""
  echo "Usage: $PROGNAME"
  echo ""
  echo "  -h               Show this page"
  echo ""
  echo "Usage: $PROGNAME --help"
  echo ""
  echo "${LICENSE}"
  echo "${COPYRIGHT}"
  echo "${AUTHOR}"
  exit 0
}

print_help() {
    print_usage
    echo ""
    echo "Icinga2 Passive Checks"
    echo ""
    exit 0
}

print_release() {
  echo "$RELEASE $AUTHOR"
}

# Parse parameters
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help)
      print_help
      exit 0
      ;;
    -v | --version)
      print_release
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      print_usage
      ;;
  esac
  shift
done

FMT='{ "exit_status": %d, "plugin_output": "%s", "performance_data": "%s", "check_source": "%s" }'

HOST=$(hostname -f)
SERVICES=("check_disk|-w 10% -c 5% -l -A -I /run/docker -I /var/lib/docker" \
    "check_load|-w 5,10,15 -c 10,15,20" \
    "check_mem|-u -C -w 85 -c 92 " \
    "check_procs|-w 780 -c 950" \
    )

for CHECK in "${SERVICES[@]}"; do

    SERVICE=$(echo "${CHECK}" | cut -d'|' -f1)
    ARGS=$(echo "${CHECK}" | cut -d'|' -f2)
    OUTPUT=$("./${SERVICE}" ${ARGS})

    STATUS=$?

    PLUGIN_OUTPUT=$(echo "${OUTPUT}" | cut -d'-' -f1)
    PERFORMANCE_DATA=$(echo "${OUTPUT}" | cut -d'|' -f2)
    JSON=$(printf "${FMT}" ${STATUS} "${PLUGIN_OUTPUT}" ["${PERFORMANCE_DATA}"] "${HOST}")

    # echo ${JSON} | jq

    curl --fail -k -s -u ${ICINGA_USER:-root}:${ICINGA_PASSWORD:-password} -H 'Accept: application/json' -X POST \
        "https://${ICINGA_HOST:-icinga2}:${ICINGA_PORT:-5665}/v1/actions/process-check-result?service=${HOST}!${SERVICE}" \
        -d "${JSON}"

done
