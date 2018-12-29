#!/usr/bin/env bash

set -e

HERE=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)

PYRE_LOCATION=$1

if [ -z "${PYRE_LOCATION}" ]; then
  echo "expected a location to Pyre" 1>&2
  exit 1
fi

if [ ! -d ${PYRE_LOCATION} ]; then
  echo "given path '${PYRE_LOCATION}' is not a directory" 1>&2
  exit 1
fi

UNAME=$(uname -s)

if [ "${UNAME}" = "Darwin" ]; then
  if [ "$(basename ${PYRE_LOCATION} .app)" = $(basename ${PYRE_LOCATION}) ]; then
    echo "I was expecting a path to the .app bundle" 1>&2
    exit 1
  else
    PYRE_LOCATION=${PYRE_LOCATION}/Contents/MacOS/Content
  fi
fi

cd ${PYRE_LOCATION} && xxh64sum -c ${HERE}/${UNAME}.xxhsums

# If you're preparing the xxhsums file, then do this instead:
#(cd ${PYRE_LOCATION} && find . -type f -exec xxh64sum {} \;) | tee ${HERE}/${UNAME}.xxhsums
