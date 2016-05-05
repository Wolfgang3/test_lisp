(asdf:defsystem custom-library :pathname "/home/wolfgang/lisp_project_copy"
  :name "custom-library"
  :version "0.0.1"
  :author "Wolfgang Furtado"
  :license "LLGPL"
  :description "this is a library for my lisp project"
  :serial t
  :components ((:file  "load-libraries")
	             (:file  "package")
               (:file  "controller")
               (:file  "asana-procedures")
               (:file  "git-procedures")
               (:file  "release-note-procedures")
               (:file  "content-procedures")

               (:module :database
                :serial t      
                :components ((:file  "db"))
               )))
