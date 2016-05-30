(asdf:defsystem custom-library :pathname "/home/wolfgang/release_notes_lisp"
  :name "custom-library"
  :version "0.0.1"
  :author "Wolfgang Furtado"
  :license "LLGPL"
  :description "this is a library for my lisp project"
  :serial t
  :components ((:file  "load-libraries")
	             (:file  "package")

               (:module :views
                :serial t      
                :components ((:file  "index")
                            (:file  "layout")
                            (:module :user
                            :serial t      
                            :components ((:file  "user-signin")
                                         (:file  "user-edit")
                                         (:file  "user-login")
                                         (:file  "user-logout")))
                            (:module :release-note
                            :serial t      
                            :components ((:file  "release-note-index")
                                         (:file  "release-note-add")
                                         (:file  "release-note-edit")
                                         (:file  "release-note-delete")
                                         (:file  "release-note-show")))

                            (:module :project
                            :serial t      
                            :components ((:file  "project-index")
                                         (:file  "project-add")
                                         (:file  "project-edit")
                                         (:file  "project-delete")))

                            ))

               (:module :controllers
                :serial t      
                :components ((:file  "controller")
                             (:file  "asana-procedures")
                             (:file  "git-procedures")
                             (:file  "release-note-procedures")
                             (:file  "content-procedures")))

               (:module :database
                :serial t      
                :components ((:file  "db"))
               )))
