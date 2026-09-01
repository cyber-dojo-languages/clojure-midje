#!/bin/bash -e

# Compiles midje ahead of time, bakes the classpath a kata's test run uses, and
# dumps the class-data archive that run replays.
#
# Loading midje means clojure reading its source and compiling it, and a kata
# runs in a container that is thrown away afterwards, so without this it happens
# again on every single run. Measured against the kata the start-point ships,
# loading midje that way is about 1180 milliseconds of a 1420 millisecond run,
# and checking the facts is a rounding error next to it. Compiling it here
# brings the run to about 320.
#
# A class-data archive alone could not reach this. It holds classes loaded from
# the classpath, and the classes clojure makes while compiling midje's source
# are defined from bytes, so they are skipped. Compiling midje first is what
# turns them into classpath classes, and only then is there anything for an
# archive to hold. The two are dumped together here for that reason.
#
# All three files are read by cyber-dojo.sh.

readonly AOT_DIR=/tmp/aot
readonly AOT_JAR=/.midje-aot.jar
readonly CLASSPATH_FILE=/.classpath
readonly ARCHIVE=/.midje.jsa

cd /tmp

# Only the dependency jars are kept. lein also reports the project's own
# directories, and those name the directory this image is built in rather than
# the directory a kata runs in, which cyber-dojo.sh appends for itself. The
# paths are rewritten to /.m2, where the jars actually are, because lein reports
# them through root's home and a kata runs as the sandbox user.
lein classpath \
  | tr ':' '\n' \
  | grep '\.m2/' \
  | sed 's|^/root/\.m2/|/.m2/|' \
  | paste --serial --delimiters=: - \
  > "${CLASSPATH_FILE}"

# Compiling midje.repl compiles everything it requires, which is midje and the
# libraries midje uses.
mkdir -p "${AOT_DIR}"
java -Dclojure.compile.path="${AOT_DIR}" -cp "${AOT_DIR}:$(cat ${CLASSPATH_FILE})" \
  clojure.main -e "(compile 'midje.repl)"

# Packed into a jar rather than left as a directory of class files, because a
# dump refuses a classpath holding a non-empty directory and there would then be
# nothing to dump the archive against.
jar --create --file "${AOT_JAR}" -C "${AOT_DIR}" .

# The compiled midje goes before the jars it was compiled from, so that loading
# a namespace finds the class files rather than reading the source again.
readonly WITH_AOT="${AOT_JAR}:$(cat ${CLASSPATH_FILE})"
printf '%s' "${WITH_AOT}" > "${CLASSPATH_FILE}"

# Dumped against exactly the baked classpath, so that the classpath a kata runs
# with begins with the one the archive was dumped from; a JVM replaying an
# archive requires that, and cyber-dojo.sh appends the kata's own directory
# after these entries rather than before them.
#
# The workload is midje being loaded the way the runner loads it, bootstrap
# first. run_fact_files.clj says why that call has to come first.
java -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:ArchiveClassesAtExit="${ARCHIVE}" \
  -cp "${WITH_AOT}" \
  clojure.main -e "(require 'midje.bootstrap)(midje.bootstrap/bootstrap)(require 'midje.repl)"

# The sandbox user reads all three at run time and owns none of them.
chmod 0644 "${CLASSPATH_FILE}" "${ARCHIVE}" "${AOT_JAR}"

cat "${CLASSPATH_FILE}"
echo
ls --format=long "${CLASSPATH_FILE}" "${ARCHIVE}" "${AOT_JAR}"
