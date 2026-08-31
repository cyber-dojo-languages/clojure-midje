#!/bin/bash -e

# Dumps a class-data archive for the JVM that runs a kata's tests.
#
# A kata runs in a container that is thrown away afterwards, so the JVM loads
# lein's, clojure's and midje's classes from the jars every single time. An
# archive holds those classes in the form the JVM wants them, and replaying one
# costs a fraction of loading them again. It is worth about a fifth of a run.
#
# The classes recorded belong to lein, clojure and midje rather than to any
# kata, so the throwaway kata below is enough to record them and the archive
# speeds up whatever kata a learner writes. It is shaped like a real one all the
# same, a namespace and a midje fact asserting against it, so that the same code
# paths are the ones that load.

readonly WORK_DIR=/tmp/dump_cds_archive
readonly ARCHIVE=/.lein/lein.jsa

mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

cp /tmp/project.clj "${WORK_DIR}/project.clj"

cat > greeter.clj <<'CLOJURE'
(ns greeter)

(defn greeting []
    (str "hello"))
CLOJURE

cat > greeter_test.clj <<'CLOJURE'
(ns greeter-test
  (:require [midje.sweet :refer :all]
            [greeter :refer :all]))

(facts "about greeting"
  (greeting) => "hello")
CLOJURE

LEIN_JVM_OPTS="-XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:ArchiveClassesAtExit=${ARCHIVE}" \
  lein midje

# The sandbox user reads this at run time and owns nothing here.
chmod 0644 "${ARCHIVE}"

cd /
rm -rf "${WORK_DIR}"

ls -l "${ARCHIVE}"
