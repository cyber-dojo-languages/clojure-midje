#!/bin/bash -Eeu

# Writes the /tmp/project.clj that the classpath and the ahead-of-time
# compilation are computed from.
#
# The clojure version is read from the base image rather than written down
# here. The base resolves the newest stable release when it is built and
# records it, so reading it is what keeps this image asking for the clojure
# that is actually present. A kata runs with no network, so a dependency this
# file names that the base did not prefetch could not be had.
#
# There is no lein plugin among these. Nothing in a kata starts lein, so
# nothing there would load one.

readonly MIDJE_VERSION=1.10.10

readonly VERSIONS=$(cat /versions.json)
readonly REGEX='"clojure":"([0-9.]+)"'
if [[ ! ${VERSIONS} =~ ${REGEX} ]]; then
  echo "ERROR: /versions.json has no clojure property: ${VERSIONS}" >&2
  exit 1
fi
readonly CLOJURE_VERSION="${BASH_REMATCH[1]}"

cat > /tmp/project.clj <<EOF
(defproject hiker "1.0.0"
  :description "Run midje tests inside cyber-dojo"
  :dependencies [[org.clojure/clojure "${CLOJURE_VERSION}"]
                 [midje "${MIDJE_VERSION}"]]
  :source-paths ["."])
EOF

# Records midje alongside clojure, so everything the image's version numbers
# are needed for can read them from the image instead of repeating them.
echo "{\"clojure\":\"${CLOJURE_VERSION}\",\"midje\":\"${MIDJE_VERSION}\"}" > /versions.json
