#!/bin/bash -Eeu

# Records in /versions.json the midje that lein resolved for /tmp/project.clj,
# which asks for whatever release is newest. Read from the classpath, so the
# record is the jar a kata actually loads.

# Appends one test framework to the test_frameworks list the base image
# wrote in /versions.json, keeping any entry an earlier image added. Stops
# the build if the list is not found, rather than record nothing.
add_test_framework()
{
  local -r name="${1}"
  local -r version="${2}"
  local -r entry="{\"name\": \"${name}\", \"version\": \"${version}\"}"
  if grep -q '"test_frameworks": \[\]' /versions.json; then
    sed -i "s|\"test_frameworks\": \[\]|\"test_frameworks\": [${entry}]|" /versions.json
  else
    sed -i "/\"test_frameworks\": \[/s|}\]|}, ${entry}]|" /versions.json
  fi
  if ! grep -q -F "${entry}" /versions.json; then
    echo "Could not add ${name} to /versions.json" >&2
    cat /versions.json >&2
    exit 1
  fi
}

cd /tmp
readonly MIDJE_VERSION=$(lein classpath \
  | tr ':' '\n' \
  | sed -n 's|.*/midje/midje/\([^/]*\)/midje-.*\.jar$|\1|p')

if [ -z "${MIDJE_VERSION}" ]; then
  echo 'Could not find the midje jar on the classpath' >&2
  exit 1
fi

add_test_framework Midje "${MIDJE_VERSION}"
cat /versions.json
