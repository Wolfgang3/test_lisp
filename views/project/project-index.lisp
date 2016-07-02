(in-package :mypackage)

(push (create-regex-dispatcher "^/project$" 'project-index) *dispatch-table*)


;; display all the projects of the user
(defun project-index ()
  (if (eq (get-user) nil)
    (redirect "/user-login"))
  (standard-page
    (:title "All projects")
    (:div :class "container"
      (:div :class "row"
        (:div :class "col-md-2")
  (:div :class "col-md-8" :style "text-align:center"
     (:a :style "font-size: 16px" :class "btn btn-primary" :href "project/add" "Create new project"))
        (:div :class "col-md-2"))
      (:div :class "row"
        (:div :class "col-md-2")
  (:div :class "col-md-8" :style "text-align: center;"
    (:table :class "table" 
      (:thead :class "align-thead"
        (:tr
          (:th "Project Name")
          (:th "Created on")
          (:th "Action")))
      (:tbody :id "align-tbody"
       (all-project-rows-of-user)))
  (:div :class "col-md-2"))))))

(defun all-project-rows-of-user ()
  (let* ((user-login-id (get-user))
   (list (get-objs-list-from-query :table 'project :foreign-key-name 'user-id :foreign-key-id user-login-id)))
    
    (dolist (proj list)
    (cl-who:with-html-output (*standard-output* nil :indent t)
      (:tr
      (:td (fmt "~a" (project-name proj)))
      (:td (fmt "~a" (convert-univeral-time-to-timestamp (project-created-date proj))) )
      (:td (:a :class "btn btn-success" :href (concatenate 'string "/project/" (write-to-string (project-id proj)) "/release-note") "go to")
      (:a :class "btn btn-warning" :href (concatenate 'string "/project/" (write-to-string (project-id proj)) "/edit") "Edit")
      (:a :class "btn btn-danger" :href (concatenate 'string "/project/" (write-to-string (project-id proj)) "/delete") "delete")))))))
