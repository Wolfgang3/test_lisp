
(in-package :mypackage)

(push (create-regex-dispatcher "^/project/[0-9]+/release-note$" 'release-notes-index) *dispatch-table*)

(defun get-project-id-from-uri ()
  "Returns the project id from the URI request."
  (car (cl-ppcre:all-matches-as-strings "[0-9]+" (request-uri *request*))))

(defun get-release-id-from-uri ()
  "Returns the project id from the URI request."
  (car (cdr (cl-ppcre:all-matches-as-strings "[0-9]+" (request-uri *request*)))))


;; display all the release notes of the project
(defun release-notes-index ()
  (standard-page
    (:title "All Release Notes")
    (:div :class "container"
      (:div :class "row"
        (:div :class "col-md-2")
	(:div :class "col-md-8" :style "text-align:center"
	   (:a :style "font-size: 16px" :class "btn btn-primary" :href "release-note/add" "Add new release note"))
        (:div :class "col-md-2"))
      (:div :class "row"
        (:div :class "col-md-2")
	(:div :class "col-md-8" :style "text-align: center;"
	  (:table :class "table" 
	    (:thead :class "align-thead"
	      (:tr
	        (:th "Release note title")
		(:th "Start date")
		(:th "End Date")
		(:th "Action")))
	    (:tbody :id "align-tbody"
	     (all-release-note-rows-of-project)))
	(:div :class "col-md-2"))))))


(defun all-release-note-rows-of-project ()
  (let* ((proj-id (get-project-id-from-uri))
	 (list (get-objs-list-from-query :table 'release-note :foreign-key-name 'project-id :foreign-key-id proj-id)))
    
    (dolist (rn list)
    (cl-who:with-html-output (*standard-output* nil :indent t)
      (:tr
      (:td (fmt "~a" (release-note-title rn)))
      (:td (fmt "~a" (convert-univeral-time-to-timestamp (release-note-start-date rn))) )
      (:td (fmt "~a" (convert-univeral-time-to-timestamp (release-note-end-date rn))))
      (:td (:a :class "btn btn-success" :href (concatenate 'string "/project/" proj-id "/release-note/" (write-to-string (release-note-id rn)) "/view") "view")
	   (:a :class "btn btn-warning" :href (concatenate 'string "/project/" proj-id "/release-note/" (write-to-string (release-note-id rn)) "/edit") "Edit")
	   (:a :class "btn btn-danger" :href (concatenate 'string "/project/" proj-id "/release-note/" (write-to-string (release-note-id rn)) "/delete") "delete")))))))

;;to get all the object of the matching foreign key
(defun get-objs-list-from-query (&key table foreign-key-name foreign-key-id)
  (return-from get-objs-list-from-query (query-dao table (:select '* :from table :where (:= foreign-key-name foreign-key-id)))
  ))

;(get-objs-list-from-query :table 'release-note :foreign-key-name 'project-id :foreign-key-id 1)

;(query-dao 'release-note (:select 'id :from 'release-note :where (:= 'project-id 1)))
