;;============== lisp project
;;=========== Generate Release notes
;;

;;======= includes ========
(ql:quickload :simple-date-time)
(ql:quickload :local-time)
(ql:quickload :jsown)
(ql:quickload :cl-json)
(ql:quickload :drakma)
(ql:quickload :hunchentoot)
(ql:quickload :cl-who)
(ql:quickload :parenscript)
(ql:quickload :postmodern)
(ql:quickload :yason)

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
             (:td (:input :type :number :name "userid")))
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
;;git token= 0db42a2a18ffbeb1714fa9f8a50e1b80578290a8
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

;; get git_repo id from project_id
(defun get-gr-id-from-project-id (project_id)
  (let ((gr_id (query (:select 'gr_id :from 'git_repo :where (:= 'project_id project_id)))))
  (return-from get-gr-id-from-project-id (car (car gr_id)))
  ))

;; get start_date or end_date from release_id
(defun get-date-from-release-id (which_date release_id)
  (let ((date (query (:select (:to_char which_date "YYYY-MM-DD") :from 'release_note :where (:= 'release_id release_id)))))
  (return-from get-date-from-release-id (car (car date)))
  ))

;(GET-DATE-FROM-RELEASE-ID 'start_date "1")
;;=> to convert the date in a correct format (ISO-8601)(for asana api)
(defun convert-date (stamp)
  (local-time:format-timestring nil
     (local-time::parse-timestring stamp) :format '((:year 4) "-" (:month 2) "-" (:day 2) "T" (:hour 2) ":" (:min 2) ":" (:sec 2) "Z")))

;;================= save all the commits in db ============= 
;; get  all git commits(sha,message) of the project repo the commits  from *str-date* to *end-date*
(defun save-all-git-commits (release_id)
  (let* ((proj_id (get-project-id-from-release-id release_id))
	 (gr_id (get-gr-id-from-project-id proj_id))
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
	 (query (:insert-into 'commit :set 'gr_id gr_id 'release_id release_id 'message (jsown:val (jsown:val  rec "commit") "message") 'sha_key (jsown:val  rec "sha") 'date (jsown:val (jsown:val (jsown:val  rec "commit") "committer") "date")))
	 )))

;;===========================================================
;=> (save-all-git-commits "1")

;;================ save all the tasks in db==================

;; get asana_project_id from users main project_id
(defun get-asana-id-from-project-id (project_id)
  (let ((asana_project_id (query (:select 'asana_project_id :from 'asana_project :where (:= 'project_id project_id)))))
    (return-from get-asana-id-from-project-id (car (car asana_project_id)))))

;; get ap_id of the table asana_project from project_id
(defun get-ap-id-from-project-id (project_id)
  (let ((ap_id (query (:select 'ap_id :from 'asana_project :where (:= 'project_id project_id)))))
    (return-from get-ap-id-from-project-id (car (car ap_id)))))


;;=> check if task date is less then end_date
;;   (task_date < end_date)
(defun is-task-date-less-then-end-date? (task_date end_date)
  (local-time:timestamp< (local-time:parse-timestring task_date) (local-time:parse-timestring end_date)))

;;=> get all the task which are completed_since the start_date
(defun get-tasks-completed-since (asana_token asana_proj_id start_date)
  (let* ((url (concatenate 'string "https://app.asana.com/api/1.0/projects/" asana_proj_id "/tasks"))
	 (json (jsown:parse
		(drakma:http-request url
		       :parameters (list (cons "access_token" asana_token)
			     (cons "completed_since" (convert-date start_date))			  
			     (cons "opt_fields"  "completed_at,name,assignee.name" ))))))
    (return-from get-tasks-completed-since json)
    ))
;;(get-tasks-completed-since "0/af8d04325c718270be55efe98be24869" "113203241574212" "2016-04-20")

(defun save-all-asana-tasks (release_id)
  (let* ((proj_id (get-project-id-from-release-id release_id))
	 (ap_id (get-ap-id-from-project-id proj_id))
	 (asana_proj_id (get-asana-id-from-project-id proj_id))
	 (asana_token (get-token-from-projectid 'asana_token proj_id))
	 (start_date (get-date-from-release-id 'start_date release_id))
	 (end_date (get-date-from-release-id 'end_date release_id)))

    (loop for rec in (jsown:val (get-tasks-completed-since asana_token asana_proj_id start_date) "data")
       do
	 (let* ((task_date (jsown:val rec "completed_at"))
		(task_name (jsown:val rec "name"))
		(task_id (jsown:val rec "id"))
		(assignee_obj (jsown:val rec "assignee"))
		)
	   (if (not (eq task_date NIL))
	       (if (eq (is-task-date-less-then-end-date? task_date end_date) T)   
	    (query (:insert-into 'task :set 'ap_id ap_id 'release_id release_id 'asana_task_id task_id 'name task_name 'assignee_id  (jsown:val assignee_obj "id") 'completed_at task_date))
	    ))))
    ))
;=> (SAVE-ALL-ASANA-TASKS "1")
;;===========================================================


;;================ save all the pr's  in db  ================

;;check if the closed date falles between start_date and end_date
;;  this will return T if it satisfies
(defun pr-date-check (closed_at start_date end_date)
  (and (local-time:timestamp< (local-time:parse-timestring closed_at) (local-time:parse-timestring end_date))
       (local-time:timestamp> (local-time:parse-timestring closed_at) (local-time:parse-timestring start_date)))  
  )

(defun save-all-pull-requests (release_id)
  (let* ((proj_id (get-project-id-from-release-id release_id))
	 (gr_id (get-gr-id-from-project-id proj_id))
	 (repo_name (get-repo-name-from-project-id proj_id))
	 (url (concatenate 'string "https://api.github.com/repos/" repo_name "/pulls"))
	 (git_token (get-token-from-projectid 'git_token proj_id))
	 (start_date (get-date-from-release-id 'start_date release_id))
	 (end_date (get-date-from-release-id 'end_date release_id))
	 (json (jsown:parse
	       (drakma:http-request url
		 :parameters (list (cons "access_token" git_token) 
				   (cons "state" "closed")
				   (cons "per_page" "100"))))))

    (loop for rec in json
       do
	 (let* ((closed_at (jsown:val  rec "closed_at"))
		(pr_title (jsown:val  rec "title"))
		(pull_request_id (jsown:val  rec "number")))
	   (if (eq (pr-date-check closed_at start_date end_date) T)   
	       (query (:insert-into 'pull_request :set 'gr_id gr_id 'release_id release_id 'pull_request_id pull_request_id  'title pr_title 'date closed_at)))))
    ))
;;===========================================================


;;============ add section for the release content ===========
(defun add-section (release_id title)
  (query (:insert-into 'section :set 'release_id release_id 'sec_title title))
  )

;;=========== add content to the release note ===============
;; adding content by passing either(commit_id/task_id/pull_request_id)
(defun add-content-to-release-note (which_key key sec_id  title description completed_date)
  (query (:insert-into 'content :set which_key key 'sec_id sec_id 'title title 'description description 'completed_date completed_date))
  )

;;=> (add-content-to-release-note 'c_id  "1" "1" "title 1" "decription 1" "2016-04-30")

;;

;;;;;;;;;;;;;;;;; new clos object ;;;;;;;;;;;;;;;;;;;;
(defclass user ()
  ((user_id :initarg :user_id
	    :reader user-user_id)
   (name :initarg :name
	 :reader user-name)
   (email_id :initarg :email_id
	     :reader user-email_id)
   (password :initarg :password
	     :reader user-password)
   (proj_list :initarg :proj_list
	      :reader user-proj_list)))

(defparameter user1 (make-instance 'user :user_id 1 :name "wolfgang furtado" :email_id "wolfgang_furtado@yahoo.com" :password 'wolfgang@3 :proj_list (list)))

;; adding projects to the user
(setf (user-proj_list user1) (list (user-proj_list user1) 'obj1))

;; method of the class
(defun add-user (name email_id password proj_list)
  (make-instance 'user :user_id user_id :name name :email_id email_id :password password :proj_list proj_list))

;; creating a instance of the class
(defparameter user1 (add-user  "wolfgang furtado" "wol@gmail.com" 'Wolfgang3 (list)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; project class
(defclass project ()
  ((project_id :col-type serial :initarg :project_id
	       :reader project_id)
   (user_id :col-type integer :initarg :user_id
	    :reader project-user_id)
   (name :col-type (varchar 30) :initarg :name
	 :reader project-name)
   (git_token :col-type string :initarg :git_token
	      :reader project-git_token)
   (asana_token :col-type string :initarg :asana_token
		:reader project-asana_token)
   (created_date :col-type (or db-null timestamp) :col-default (current_timestamp 2)   
		:initarg :created_date
		:reader project-created_date))
  (:metaclass dao-class)
  (:keys project_id))

(insert-dao (make-instance 'country :name "The Netherlands"
                                    :inhabitants 16800000
                                    :sovereign "Willem-Alexander"))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
