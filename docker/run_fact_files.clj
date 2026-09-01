;; Checks the facts in the kata's files and exits 0 when they all pass and 1
;; when they do not.
;;
;; The files are named by the glob in cyber-dojo.sh. Nothing here knows the names
;; the start-point ships; a learner writes source and fact files named for the
;; exercise they are doing, and those are what arrive here.

(require 'midje.bootstrap)

;; Midje calls this itself, from the top of midje.sweet, above that file's own ns
;; form. It reads *ns*, and a namespace compiled ahead of time is loaded through
;; Class.forName, whose static initializer runs with no *ns* bound, so midje's
;; own call throws there. Calling it here, where *ns* is bound, sets the defonce
;; flag it guards itself with and leaves midje's call with nothing to do.
;; Binding *ns* around the require instead does not work; that still throws.
(midje.bootstrap/bootstrap)

(require 'midje.repl)

(defn- declared-namespace
  "Answers the namespace a file declares, or nil when its first form is not ns."
  [filename]
  (with-open [reader (java.io.PushbackReader. (clojure.java.io/reader filename))]
    (let [form (read {:eof nil :read-cond :allow} reader)]
      (when (and (seq? form) (= 'ns (first form)))
        (second form)))))

;; Every .clj file is named, so facts are checked wherever they are written
;; rather than only in the files whose names end in _test. project.clj is named
;; too and drops out here, its first form being defproject rather than ns.
(let [namespaces (keep declared-namespace *command-line-args*)]
  (System/exit
    (try
      (if (zero? (:failures (apply midje.repl/load-facts namespaces))) 0 1)
      (catch Exception _
        ;; A file that would not load has already been named, with the position
        ;; in it, by the lines midje printed above. Midje goes on to hand the
        ;; namespace it could not load to clojure.test, which throws for it;
        ;; that says nothing the learner does not already know, and printing it
        ;; would bury the line that does. A file that will not load is a failure.
        1))))
