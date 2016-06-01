
;;======= package ========
(defpackage mypackage
  (:use :cl
        :cl-who
        :hunchentoot
        :local-time
        :jsown
        :parenscript
        :postmodern
  ))
(in-package :mypackage)
;;========================

;;======= postgres connection ========
(asdf:oos 'asdf:load-op :postmodern)
(use-package :postmodern)

;;(db,user,pw,server)
(connect-toplevel "lisp" "postgres" "star" "localhost")

;;======= assign port and start server ========
(defvar *h* (make-instance 'easy-acceptor :port 3000))
(hunchentoot:start *h*)

;;to tel drakma that thet content-type returned is json
(setq drakma:*text-content-types* (cons '("application" . "json")
					drakma:*text-content-types*))


