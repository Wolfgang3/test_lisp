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
;;=========================

;;======= package ========
(defpackage mypackage
  (:use :cl
        :cl-who
        :hunchentoot
	:local-time
	:jsown
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
;;git token= a48dd1850229082e31afb5b21dd8ebc52441602f
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
     (:form  :action "/release_notes/project_form_check" :method :post	 
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
  (query (:insert-into 'project :set 'user_id (get-user-id) 'name projnm 'git_token git_tok 'asana_token asana_tok))
    (redirect "/release_notes/login_successful"))

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
;;==================================================

;;======= select the git repo and asana project ========
(push (create-regex-dispatcher "/release_notes/project/[0-9]+/select_repo_and_task" 'select-repo-and-task) *dispatch-table*)

;; returns the project id from the URI request.
(defun get-projectid-from-uri ()
  (car (cl-ppcre:all-matches-as-strings "[0-9]+" (request-uri *request*))))

(defun select-repo-and-task ()
  (get-projectid-from-uri)
  )
