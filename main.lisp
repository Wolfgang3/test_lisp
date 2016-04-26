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

;;============= dispatcher table ==============
(push (create-static-file-dispatcher-and-handler "/bootstrap.css" "lisp_project/bootstrap/css/bootstrap.css") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/style.css" "lisp_project/style.css") *dispatch-table*)
(push (create-regex-dispatcher "/test-new-save" 'test-new-save) *dispatch-table*)
(defun test-new-save ()
  )
;;=============================================
(hunchentoot:define-easy-handler (func :uri "/try") ()
  (standard-page (:title "test 1 2 3")
       (:li (format s "~s" "hey"))))
;; ++++++++++++++++++++++++++ main ++++++++++++++++++++++++++
(setq drakma:*text-content-types* (cons '("application" . "json")
					drakma:*text-content-types*))


;;=> to convert the given time into a timstemp 
(setf *str-date* (local-time:format-timestring nil (local-time:parse-timestring "2016-04-18")))
(setf *end-date* (local-time:format-timestring nil (local-time:parse-timestring "2016-04-21")))

;;=> to convert the date in a correct format (ISO-8601)(for asana api)
(defun convert-date (stamp)
  (local-time:format-timestring nil
     (local-time::parse-timestring stamp) :format '((:year 4) "-" (:month 2) "-" (:day 2) "T" (:hour 2) ":" (:min 2) ":" (:sec 2) "Z")))

;;=> to save the json of the list of tasks completed after the *str-date* the asana api
(defparameter *list*
  (jsown:parse
   (drakma:http-request *asana-api-tasks*
           :parameters (list (cons "access_token" *asana-token*)
			     (cons "completed_since" (convert-date *str-date*))
					  
			     (cons "opt_fields"  "completed_at" )))))

(jsown:to-json *list*)

;;=> check the passes task date against *end-date*(task_date < *end-date*)
(defun check_task_date_with_end_date (task_date)
  (local-time:timestamp< (local-time:parse-timestring task_date) (local-time:parse-timestring *end-date*)))

;;=>get all the completed task ids ()
;;;;; (the *list* returns all the incomplete tasks also and als it retuns all the tasks completed after the *end-date* also)
;;;testing
(defun get-tasks-ids ()
  (setf *completed-tasks-id* nil)
  (jsown:do-json-keys (keyword value)
      (car (cdr *list*))
      ;(format T "~A => ~A:" keyword  (rest (first value)))
    (let ((task-id (rest (first value)))
	  (task-date (rest (car (last value)))))
      (if (not (eq task-date NIL))
        ;(format T "date: ~A" (check_task_date_with_end_date (rest (car (last value)))))
	(if (eq (check_task_date_with_end_date task-date) T)   
	    (setf *completed-tasks-id* (append *completed-tasks-id* (list task-id)))
	    ;(format T "false")
    )))))
;;=> after the this function all the completed task will be saved in *completed-tasks-id*

;https://app.asana.com/api/1.0/workspaces/113202625720682/projects
;https://app.asana.com/api/1.0/tasks/114120863922696?opt_pretty 

(defun get-task-details ()
  (loop for rec in *completed-tasks-id*
     do
       (let* ((stid (concatenate 'string "https://app.asana.com/api/1.0/tasks/" (write-to-string rec)))
	      (json-obj (jsown:parse (drakma:http-request stid
	         :parameters (list (cons "access_token" *asana-token*))))))
	 
	 (format t "~s~%" (jsown:val (rest (car (cdr json-obj))) "name" ))
	 )))

;;;++++++++++ for Git requests
(defvar *git-token* "a48dd1850229082e31afb5b21dd8ebc52441602f")
(defparameter *git-api* "https://api.github.com")

;;save the user name from the json
(defparameter *git-username*
  (let ((json (jsown:parse
   (drakma:http-request "https://api.github.com/user"
           :parameters (list (cons "access_token" *git-token*))))))
   (jsown:val json "login")
  ))

;;get the list of all the repos
(defun get-repo-list ()
  (let ((json (jsown:parse
   (drakma:http-request "https://api.github.com/user/repos"
          :parameters (list (cons "access_token" *git-token*)
		            (cons "per_page" "100")
			    (cons "sort" "created"))))))

    (loop for rec in json
      do	   
      (format t "~s~%" (jsown:val (cdr rec) "full_name")))))

;; save the selected repo from the list
(defvar *selected-repo* "VacationLabs_exercises")

(setf *str-date* (local-time:format-timestring nil (local-time:parse-timestring "2016-03-05")))
(setf *end-date* (local-time:format-timestring nil (local-time:parse-timestring "2016-03-07")))

(defvar *commits-sha-list*)

;; get the commits sha from *str-date* to *end-date*
(defun get-commits-list ()
  (setf *commits-sha-list* nil)
  (let* ((url (concatenate 'string "https://api.github.com/repos/" *git-username* "/" *selected-repo* "/commits"))
	(json (jsown:parse
   (drakma:http-request url
          :parameters (list (cons "access_token" *git-token*)
		            (cons "since" (convert-date *str-date*))
			    (cons "until"(convert-date  *end-date*))
			    (cons "per_page" "100"))))))
    (loop for rec in json
       do
	 (setf *commits-sha-list* (append *commits-sha-list* (list (jsown:val  rec "sha")))))))
;now the *commits-sha-list* will contain all the commits sha list

;get the commit details from the commit *commits-sha-list*
(defun get-commits-details ()
  (loop for rec in *commits-sha-list*
     do
       (let* ((url (concatenate 'string "https://api.github.com/repos/" *git-username* "/" *selected-repo* "/commits/" rec))
	      (json-obj (jsown:parse (drakma:http-request url
	         :parameters (list (cons "access_token" *git-token*))))))
	 
	 (format t "~s~%" (jsown:val (jsown:val  json-obj "commit") "message")))))

;get all the pull request from the repo
(defvar *pull-request-list*)
(defun get-pull-requests ()
  (setf *pull-request-list* nil)
  (let* ((url (concatenate 'string "https://api.github.com/repos/" *git-username* "/" "test_lisp" "/pulls"))
	(json (jsown:parse
           (drakma:http-request url
                  :parameters (list (cons "access_token" *git-token*)
		                    (cons "sort" "created"))))))
    (loop for rec in json
       do
	 (setf *pull-request-list* (append *pull-request-list* (list (jsown:val  rec "title")))))))
;now the *pull-request-list* will contain all the prs name


