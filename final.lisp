;;============== lisp project
;;=========== Generate Release notes
;;

;;======= includes ========
(ql:quickload :simple-date-time)
(ql:quickload :local-time)
(ql:quickload :jsown)
(ql:quickload :drakma)
(ql:quickload :hunchentoot)
(ql:quickload :cl-who)
(ql:quickload :parenscript)
(ql:quickload :postmodern)
;;=========================

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
;;===================================

;;======= variables ========
(defvar *str-date*)
(defvar *end-date*)
(defvar *completed-tasks-id*)
(defparameter *asana-api-tasks* "https://app.asana.com/api/1.0/projects/113203241574212/tasks")
(defvar *asana-token* "0/af8d04325c718270be55efe98be24869")
(defparameter *git-api* "https://api.github.com")
(defvar *git-token* "a48dd1850229082e31afb5b21dd8ebc52441602f")
;;==========================

;;======= assign port and start server ========
(defvar *h* (make-instance 'easy-acceptor :port 3000))
(hunchentoot:start *h*)
;;=============================================

;;++++++++++++++++ standard page ++++++++++++++++++
(defmacro standard-page ((&key title) &body body)
  `(cl-who:with-html-output-to-string (s)
     (:html
      (:head 
       (:meta :content "text/html" :charset "utf-8")
       (:title ,title)
       (:link :href "style.css" :rel "stylesheet" :type "text/css")
       (:script :src "/script.js" ))
      (:body
       (:h2 :class "test" ,title)
       ,@body))))
;;++++++++++++++++++++++++++++++++++++++++++++++++

;;to tel drakma that thet content-type returned is json
(setq drakma:*text-content-types* (cons '("application" . "json")
					drakma:*text-content-types*))

;;============= dispatcher table ==============
(push (create-static-file-dispatcher-and-handler "/bootstrap.css" "lisp_project/bootstrap/css/bootstrap.css") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/style.css" "lisp_project/style.css") *dispatch-table*)

;;=============================================

;;======================= login =============
(defun get-user-id ()
  (hunchentoot:session-value 'user_id))

(push (create-regex-dispatcher "/release_notes/login" 'login-check) *dispatch-table*)
(push (create-regex-dispatcher "/release_notes/login_successful" 'login-successful) *dispatch-table*)

(defun display-login (&key with-warning)
  (cl-who:with-html-output-to-string (s)
    (:html
    (:head (:title "Login page"))
    (:meta :http-equiv "Content-Type" :content "text/html;charset=utf-8")
    (:body
     (:h1 ":::: Login :::::")
     (when with-warning (format s "<b style=\"color:red\"> ~a </b>" with-warning))
     (:form  :action "/release_notes/login" :method :post	 
           (:table :border 0 :cellpadding 4 :cellspacing 4
            (:tr
             (:td "User Id: ")
             (:td (:input :type :text :name "userid")))
            (:tr
             (:td "Password: ")
             (:td (:input :type :password :name "pass")))
            (:tr
             (:td :colspan 2
		  (:input :type "submit" :value "login")))))))))

(defun login-check ()
  (when (get-user-id)
    (redirect "/release_notes/login_successful")
    (hunchentoot:remove-session hunchentoot:*session*))
  (let ((userid (hunchentoot:post-parameter "userid"))
        (pass (hunchentoot:post-parameter "pass")))
    (if (and userid pass)
	(multiple-value-bind (data n)
	    (query (:select 'user_id :from 'system_user :where (:and (:= 'user_id userid) (:= 'password pass))))
	  (cond ((= n 0)
		 (display-login :with-warning "invalid login"))
		(t (set-cookie "user-id" :value (car (car data)))
		   (hunchentoot:start-session)
		   (setf (hunchentoot:session-value 'user_id) (car (car data)) )
		   (redirect "/release_notes/login_successful"))
		))
	(display-login))))
  

;login successfull
(defun login-successful ()
  (cl-who:with-html-output-to-string (s)
    (:html
     (:body  
      (:h1 (format s "successful"))
      (:h2 (format s "cookie:user-id: ~a" (cookie-in "user-id")))
      (:h2 (format s "session:user-id: ~a" (hunchentoot:session-value 'user_id)))
      
       ;(query (:insert-into 'test :set 'int (get-user-id)))
      (:h2 (format s "~a" (get-user-id)))))
    ))
;;==================================================


;;============= add project ==============
;;git token= c1e6be6c1de8c9460d69f63ad4ddc965440a13d1
;;asana token= 0/af8d04325c718270be55efe98be24869

(push (create-regex-dispatcher "/release_notes/project/add_project" 'add-project-form) *dispatch-table*)
(push (create-regex-dispatcher "/release_notes/project/project_form_check" 'project-form-check) *dispatch-table*)


(defun add-project-form (&key with-warning)
  (cl-who:with-html-output-to-string (s)
    (:html
    (:head (:title "add a project"))
    (:meta :http-equiv "Content-Type" :content "text/html;charset=utf-8")
    (:body
     (:h1 ":::: add project :::::")
     (when with-warning (format s "<b style=\"color:red\">~a</b>" with-warning))
     (:form  :action "/release_notes/project/project_form_check" :method :post	 
           (:table :border 0 :cellpadding 4 :cellspacing 4
            (:tr
             (:td "Project Name: ")
             (:td (:input :type :text :name "projnm")))
            (:tr
             (:td "Git Token: ")
             (:td (:input :type :text :name "git_tok")))
	    (:tr
             (:td "Asana Token: ")
             (:td (:input :type :text :name "asana_tok")))
            (:tr
             (:td :colspan 2
		  (:input :type "submit" :value "login")))))))))

;; check for validation on project-form
(defun project-form-check ()
  (let ((projnm (hunchentoot:post-parameter "projnm"))
	(git_tok (hunchentoot:post-parameter "git_tok"))
	(asana_tok (hunchentoot:post-parameter "asana_tok")))
    (if (eq (git-token-check git_tok) 'false)
	(add-project-form :with-warning "invalid git token")
	(if (eq (asana-token-check asana_tok) 'false)
	    (add-project-form :with-warning "invalid asana token")
	    (add-project-save projnm git_tok asana_tok)))))

;; to save the project in the db after the validation
(defun add-project-save (projnm git_tok asana_tok)
  (let ((current_id (query (:insert-into 'project :set 'user_id (get-user-id) 'name projnm 'git_token git_tok 'asana_token asana_tok :returning 'project_id))))
  (redirect (concatenate 'string "/release_notes/project/" (write-to-string (car (car current_id))) "/select_repo_and_task")
    )))

;;check if the git token is valid of invalid
(defun git-token-check (token)
  (let ((status (nth-value 1 (drakma:http-request "https://api.github.com/user"
			            :parameters (list (cons "access_token" token))))))
    (if (eq status 200)
	(return-from git-token-check 'true)
	(return-from git-token-check 'false))))


;;check if the asana token is valid or invalid
(defun asana-token-check (token)
  (let ((status (nth-value 1 (drakma:http-request "https://app.asana.com/api/1.0/users/me"
			            :parameters (list (cons "access_token" token))))))
    (if (eq status 200)
	(return-from asana-token-check 'true)
	(return-from asana-token-check 'false))))
;;=====================================================

;;======= select the git repo and asana project ========
(push (create-regex-dispatcher "/release_notes/project/[0-9]+/select_repo_and_task" 'select-repo-and-task) *dispatch-table*)

(defvar *lol* nil) 
;; returns the project id from the URL request.
(defun get-projectid-from-uri ()
  (car (cl-ppcre:all-matches-as-strings "[0-9]+" (request-uri *request*))))

;; return token by passing project id and which-token(git/asana)
(defun get-token-from-projectid (which_token proj_id)
  (let ((token (query (:select which_token :from 'project :where (:= 'project_id proj_id)))))
  (return-from get-token-from-projectid (car (car token)))
  ))

;; from to select the git repo and asana project
(defun select-repo-and-task ()
  (let* ((proj_id (get-projectid-from-uri))
         (git_token (get-token-from-projectid 'git_token proj_id))
	 (asana_token (get-token-from-projectid 'asana_token proj_id)))
  (cl-who:with-html-output-to-string (s)
    (:html
    (:head (:title "Select repo and asana project"))
    (:meta :http-equiv "Content-Type" :content "text/html;charset=utf-8")
    (:body
     (:h1 ":::: Select repo and asana project :::::")
     (:form  :action "/release_notes/project_form_check" :method :post  
           (:table :border 0 :cellpadding 4 :cellspacing 4
            (:tr
             (:td "Select the git repo: ")
	     (:td (:select :name "git_repo"
		      (get-all-git-repos s git_token))))
            (:tr
             (:td "Select the asana workspace: ")
	     (:td (:select :name "asana_workspace" :onclick (ps)
		      (get-all-asana-workspaces s asana_token))))

	    (:tr
             (:td "Select the project: ")
	     (:td (:select :name "asana_project" :onclick (ps)
		      (get-all-asana-projects s asana_token "113202625720682"))))
	    (:input :type :hidden :name "project_id" :value proj_id)
	   
            (:tr
             (:td :colspan 2
		  (:input :type "submit" :value "Save"))))))))))


(defun get-selected-workspace-id (work_id)
  (ps "(alert \"hello\" )" )
  (setf *lol* work_id)
  )
;;(chain document (cookie == ='username 'John))

;;get all git repos list
(defun get-all-git-repos (s token)
  (let ((json (jsown:parse
	        (drakma:http-request "https://api.github.com/user/repos"
		       :parameters (list (cons "access_token" token)
					 (cons "per_page" "100")
					 (cons "sort" "created"))))))
    (loop for rec in json
       do
	 (format s "<option value=\"~a\">~a</option>" (jsown:val (cdr rec) "full_name") (jsown:val (cdr rec) "full_name")))))

;;get all asana workspaces
(defun get-all-asana-workspaces (s token)
  (let ((json (jsown:parse
	        (drakma:http-request "https://app.asana.com/api/1.0/workspaces"
		       :parameters (list (cons "access_token" token))))))
    (loop for rec in (rest (car (cdr json)))
       do
	 (format s "<option value=\"~a\">~a</option>" (jsown:val rec "id") (jsown:val rec "name")))))


;;get all asana projects list by passing s,token and workspace_id
(defun get-all-asana-projects (s token workspace_id)
  (let ((json (jsown:parse
	        (drakma:http-request "https://app.asana.com/api/1.0/projects"
		       :parameters (list (cons "access_token" token)
				         (cons "workspace" workspace_id))))))
    (loop for rec in (rest (car (cdr json)))
       do
	 (format s "<option value=\"~a\">~a</option>" (jsown:val rec "id") (jsown:val rec "name")))))

;;to save the repo and project in the db
(defun git-repo-and-asana-project-save (proj_id git_repo_name asana_proj_id)
  (query (:insert-into 'asana_project :set 'project_id proj_id 'asana_project_id asana_proj_id))
  (query (:insert-into 'git_repo :set 'project_id proj_id 'repo_name  git_repo_name)))

;;=====================================================


;;=================== create new release notes ================

;;save the release notes in the db
(defun release-notes-save(proj_id title start_date end_date)
  (query (:insert-into 'release_note :set 'project_id proj_id 'title title 'start_date start_date 'end_date end_date))
  )

;;when the release notes are saved all the commits of the repo
;; and the asana tasks between the start date n the end date
;;  will be brought and saved in the database 

;;get project_id from the release_id
(defun get-project-id-from-release-id (release_id)
  (let ((proj_id (query (:select 'project_id :from 'release_note :where (:= 'release_id release_id)))))
  (return-from get-project-id-from-release-id (car (car proj_id)))
    ))

;; get git repo name from project_id
(defun get-repo-name-from-project-id (project_id)
  (let ((repo_name (query (:select 'repo_name :from 'git_repo :where (:= 'project_id project_id)))))
  (return-from get-repo-name-from-project-id (car (car repo_name)))
  ))

;; get start_date or end_date from release_id
(defun get-date-from-release-id (which_date release_id)
  (let ((date (query (:select (:to_char which_date "YYYY-DD-MM") :from 'release_note :where (:= 'release_id release_id)))))
  (return-from get-date-from-release-id (car (car date)))
  ))

;(GET-DATE-FROM-RELEASE-ID 'start_date "1")
;;=> to convert the date in a correct format (ISO-8601)(for asana api)
(defun convert-date (stamp)
  (local-time:format-timestring nil
     (local-time::parse-timestring stamp) :format '((:year 4) "-" (:month 2) "-" (:day 2) "T" (:hour 2) ":" (:min 2) ":" (:sec 2) "Z")))

;; get  all git commits(sha,message) of the project repo the commits  from *str-date* to *end-date*
(defvar *end-date*)
(defvar *commits-sha-list*)
(defun get-commits-list (release_id)
  (setf *commits-sha-list* nil)
  (let* ((proj_id (get-project-id-from-release-id release_id))
	 (repo_name (get-repo-name-from-project-id proj_id))
	 (url (concatenate 'string "https://api.github.com/repos/" repo_name "/commits"))
	 (git_token (get-token-from-projectid 'git_token proj_id))
	 (start_date (get-date-from-release-id 'start_date release_id))
	 (end_date (get-date-from-release-id 'end_date release_id))
	(json (jsown:parse
	       (drakma:http-request url
		 :parameters (list (cons "access_token" git_token)
		            (cons "since" (convert-date start_date))
			    (cons "until"(convert-date  end_date))
			    (cons "per_page" "100"))))))

    (loop for rec in json
       do
	 (setf *commits-sha-list* (append *commits-sha-list* (list (jsown:val  rec "sha")))))
    ))

(GET-COMMITS-LIST "1")

(loop for rec in json
       do
	 (setf *commits-sha-list* (append *commits-sha-list* (list (jsown:val  rec "sha")))))

;;=============================================================
