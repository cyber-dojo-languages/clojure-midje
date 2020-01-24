FROM cyberdojofoundation/clojure
LABEL maintainer=frederic.merizen@soft-xki.com

ENV MIDJE_COLORIZE=false

COPY project.clj /tmp

RUN cd /tmp \
 && lein deps \
 && lein midje --help \
 && chown -R nobody /.m2

COPY red_amber_green.rb /usr/local/bin
