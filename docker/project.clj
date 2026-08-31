; The clojure version is named rather than asked for as "RELEASE", because
; "RELEASE" is whatever was published most recently, including a pre-release. It
; resolves at the time of writing to 1.13.0-alpha6, so a rebuild would prefetch
; that and leave the version the start-point asks for absent from the image. A
; kata runs with no network, so a dependency the image did not prefetch cannot
; be had.
;
; :eval-in matches the start-point's own project.clj, so that the class-data
; archive dumped from this project records the classes of the same single JVM
; that a kata's run uses.
(defproject hiker "1.0.0"
  :description "Run midje tests inside cyber-dojo"
  :dependencies [[org.clojure/clojure "1.12.4"]
                 [midje "1.10.10"]]
  :source-paths ["."]
  :eval-in :leiningen
  :plugins      [[lein-midje "3.2.2"]])
