(in-package :mypackage)

(push (create-regex-dispatcher "^/user-logout" 'user-logout) *dispatch-table*)

(defun user-logout ()
  (hunchentoot:remove-session hunchentoot:*session*)
  (redirect "/index"))
