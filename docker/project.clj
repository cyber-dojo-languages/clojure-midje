(defproject hiker "1.0.0"
  :description "Run midje tests inside cyber-dojo"
  :dependencies [[org.clojure/clojure "RELEASE"]
                 [midje "1.10.10"]]
  :source-paths ["."]
  :plugins      [[lein-midje "3.2.2"]])
