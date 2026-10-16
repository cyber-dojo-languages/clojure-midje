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
# midje is asked for as RELEASE, so the newest release is resolved when the
# image is built. record_midje_version.sh records which one that was.
#
# There is no lein plugin among these. Nothing in a kata starts lein, so
# nothing there would load one.

readonly VERSIONS=$(cat /versions.json)
readonly REGEX='"language": *\{[^}]*"version": *"([0-9.]+)"'
if [[ ! ${VERSIONS} =~ ${REGEX} ]]; then
  echo "ERROR: /versions.json has no language version: ${VERSIONS}" >&2
  exit 1
fi
readonly CLOJURE_VERSION="${BASH_REMATCH[1]}"

cat > /tmp/project.clj <<EOF
(defproject hiker "1.0.0"
  :description "Run midje tests inside cyber-dojo"
  :dependencies [[org.clojure/clojure "${CLOJURE_VERSION}"]
                 [midje "RELEASE"]]
  :source-paths ["."])
EOF
