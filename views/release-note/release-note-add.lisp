
(in-package :mypackage)

(push (create-regex-dispatcher "^/project/[0-9]+/release-note/add" 'release-notes-add) *dispatch-table*)
(push (create-regex-dispatcher "^/project/[0-9]+/release-note/save" 'release-notes-save) *dispatch-table*)

;; release-note form
(defun release-notes-add ()
  (standard-page
    (:title "Add a Release Notes")
    (:div :class "container release-note-form"
     (:form  :action "save" :method :post	 
      (:div :class "row"
	(:div :class "col-md-1")
	(:div :style "text-align:left"  :class "col-md-10"
	  (:div :class "row"  
	    (:span :style "font-size:24px;" "Release note title:")
		(:input :type :text :style "font-size:16px;" :name "title" :placeholder "Enter title name" :required "true"))
	  (:div :class "row"
	    (:h3 "Select the dates:")
	    (:div :class "col-md-6"
	      (:label "Start date:")
	      (:input :type :text :name "start-date" :id "start-date" :required "true"))
	    (:div :class "col-md-6"
	      (:label "End date:")
	      (:input :type :text :name "end-date" :id "end-date" :required "true")))
    (:br)
	  (:div :class "row"  
	    (:div :class "col-md-6"
	      (:h3 :style "text-shadow: black 1px 4px 6px;text-align:center;color:blue;" "Select Git repos")	
	        (:div :class "well" :style "height:300px;overflow: auto;"
		 (:ul :class "list-group checked-list-box"
		 (get-repo-list-checkboxes))))
	    (:div :class "col-md-6"
	      (:h3 :style "text-shadow: black 1px 4px 6px;text-align:center;color:blue;" "Select Asana projects")
	        (:div :class "well" :style "height:300px;overflow: auto;"
		 (:ul :class "list-group checked-list-box"
		(get-asana-project-checkboxes)))))
	  (:br)
	  (:div :class "row" :style "text-align: center;"
	   (:div :class "col-md-12"	 
	    (:input :id "fetch" :style "font-size: 16px" :class "btn btn-primary" :type "submit" :name "submit" :value "Fetch")))
	)
        (:div :class "col-md-1"))))))

;; get git repos checkboxes
(defun get-repo-list-checkboxes ()
  (let* ((proj-id (get-project-id-from-uri))
	(list (get-objs-list-from-query :table 'git-repo :foreign-key-name 'project-id :foreign-key-id proj-id)))
    (dolist (repos list)
      (cl-who:with-html-output (*standard-output* nil :indent t)
        (:label :class "list-group-item"	   
	  (fmt "<input id=\"checkbox-style\" type=\"checkbox\" name=\"repo-checkboxes\" value=\"~a\">~a</input>" (git-repo-id repos) (git-repo-repo-name repos)))))))

;; get asana project checkboxes
(defun get-asana-project-checkboxes ()
  (let* ((proj-id (get-project-id-from-uri))
	(list (get-objs-list-from-query :table 'asana-project :foreign-key-name 'project-id :foreign-key-id proj-id)))
    (dolist (repos list)
      (cl-who:with-html-output (*standard-output* nil :indent t)
	(:label :class "list-group-item"	   
          (fmt "<input id=\"checkbox-style\" type=\"checkbox\" name=\"asana-checkboxes\" value=\"~a\">~a</input>" (asana-project-id repos) (asana-project-name repos)))))))

;; this function will fetch all the commits ,prs and the tasks and  save it in the db, and the content will be generated
(defun release-notes-save ()
  (let* ((proj-id (get-project-id-from-uri))
	 (title (hunchentoot:post-parameter "title"))
	 (str-date (hunchentoot:post-parameter "start-date"))
	 (end-date (hunchentoot:post-parameter "end-date"))
	 (release-id (car (car (query (:insert-into 'release_note :set 'project_id proj-id 'title title 'start_date str-date 'end_date end-date :returning 'id)))))
	 (parameter (hunchentoot:post-parameters*))
	 (repo-id-checked (get-checkboxes-ids 'repo-checkboxes parameter))
	 (asana-project-id-checked (get-checkboxes-ids 'asana-checkboxes parameter)))	 
    ;; save all the commits and pr's
    (loop for id in repo-id-checked
       do
	 (save-object-list (get-git-commits :selected-repo-id id :release-id release-id :token (project-git-token (get-dao 'project proj-id))))
	 (save-object-list (get-pull-requests :selected-repo-id id :release-id release-id :token (project-git-token (get-dao 'project proj-id)))))
    ;; save all the tasks
    (loop for id in asana-project-id-checked
       do
	 (save-object-list (get-asana-tasks :selected-asana-project-id id :release-id release-id :token (project-asana-token (get-dao 'project proj-id)))))
    ;; now the content will be generated
    (make-content-of-everything :release-id release-id)
    
    (redirect (concatenate 'string "/project/" proj-id "/release-note/" (write-to-string release-id) "/view" ))
    ))

;; to get the list of checkbox selected parameters 
(defvar *id-list*)
(defun get-checkboxes-ids (which-value parameters)
  (setf *id-list* nil)
  (loop for (a . b) in parameters
     do
       (if (string= a  (string-downcase which-value))
	   (setf *id-list* (append *id-list* (list b)))) )
  (return-from get-checkboxes-ids *id-list*))


