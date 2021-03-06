(ql:quickload :hunchentoot)
(ql:quickload :cl-who)
(ql:quickload :yason)
(ql:quickload :drakma)
(ql:quickload :cl-json)
(ql:quickload :st-json)
(ql:quickload :jsown)
(ql:quickload :SIMPLE-DATE-TIME)
(ql:quickload "local-time")
(ql:quickload :alexandria)

;;;;;;;;;;date
(local-time:parse-timestring "2013-12-10")

(local-time:now)

(local-time:timestamp-difference one-timestamp another-timestamp)

(local-time:timestamp-whole-year-difference one-timestamp another-timestamp)
;;;;;;;;;;date


;;;;;;;;;;;;;;;;;;;;;
(drakma:http-request "https://api.github.com")

 (let ((stream (drakma:http-request "https://api.github.com"
				    :parameters '(("access_token" . "9640b1ee872d669e33b4fd7e8166d17bf699ff9e"))
				    )))
    (setf (flexi-streams:flexi-stream-external-format stream) :utf-8)
    (let (( tr (yason:parse stream :object-as :alist)))
      tr
    ))

;; url for passing the start and end date
https://api.github.com/repos/Wolfgang3/VacationLabs_exercises/commits?since=2016-03-05&until=2016-03-07&per_page=100&access_token=9640b1ee872d669e33b4fd7e8166d17bf699ff9e


;;;;; test2

(defvar *json*
  (cl-json:decode-json-from-source (drakma:http-request "https://api.github.com/repos/Wolfgang3/VacationLabs_exercises/commits?since=2016-03-05&until=2016-03-07&per_page=100&access_token=a48dd1850229082e31afb5b21dd8ebc52441602f"					 
					   :want-stream t)
	    ))

(json:json-bind (CODE--SEARCH--URL)
    *json*
  )


;;;;;
(setq drakma:*text-content-types* (cons '("application" . "json")
					drakma:*text-content-types*))

(defvar *out* (drakma:http-request "https://api.github.com/repos/Wolfgang3/VacationLabs_exercises/commits?since=2016-03-05&until=2016-03-07&per_page=100&access_token=9640b1ee872d669e33b4fd7e8166d17bf699ff9e" ))

(third (car (json:decode-json-from-string *out* )))

(json:with-decoder-simple-list-semantics
  (with-input-from-string
      (s *out*)
    (SIMPLE-JSON-BIND (SHA) s
      (format nil "Foo is ~s.~%" SHA ))))


(print (with-input-from-string
	   (s *out*)
	 (json:decode-json s)))

;;;;;;;;;;
;working
(defun test-json ()
  (with-input-from-string (s *out*)
    (let ((data (json:decode-json s)))
      (format nil "~a" (rest (assoc :author (car data)))) )))

;;new way
(jsown:val (car (jsown:parse (drakma:http-request "https://api.github.com/repos/Wolfgang3/VacationLabs_exercises/commits?since=2016-03-04&until=2016-03-07&per_page=100&access_token=9640b1ee872d669e33b4fd7e8166d17bf699ff9e"))) "sha")


;;asana auth token: 0/af8d04325c718270be55efe98be24869
(loop for (key . value) in (car (jsown:parse (drakma:http-request "https://api.github.com/repos/Wolfgang3/VacationLabs_exercises/commits?since=2016-03-04&until=2016-03-07&per_page=100&access_token=9640b1ee872d669e33b4fd7e8166d17bf699ff9e")))
   do (if (eq key "sha")
	  (format t "~&Key: ~a, Value: ~a." key value)
	  (format t "\nNothing changed : ~a" key)
	  ))



(defmacro report-get (report &optional key &rest keys)
  (cond
   ((null key) report)
   ((integerp key) `(report-get (nth ,key ,report)  ,@keys))
   (t `(report-get (cdr (assoc ,key ,report)) ,@keys))))


(report-get (json:decode-json-from-string *input*) :weather 0 :main)


(defparameter *input*
  "{\"coord\":{\"lon\":-123.12,\"lat\":49.25},\"weather\":{\"id\":500,\"main\":\"Rain\",\"description\":\"light rain\",\"icon\":\"10n\"},\"base\":\"cmc stations\",\"main\":{\"temp\":281.56,\"pressure\":1001,\"humidity\":93,\"temp--min\":276.15,\"temp--max\":283.15},\"wind\":{\"speed\":3.1,\"deg\":100,\"clouds\":{\"all\":90}},\"dt\":1453467600,\"sys\":{\"sunrise\":1453478139,\"sunset\":1453510389},\"id\":6173331,\"name\":\"Vancouver\",\"cod\":200}")


(defmacro destructure-jso-2 (vars json &body body)
    `(let ,(mapcar #'(lambda (var)
                       (list var `(st-json:getjso ,(string-downcase (symbol-name var)) ,json)))
                   vars)
       ,@body))


(let ((params (car (st-json:read-json-from-string *out*))))
    (destructure-jso-2 (author:login)
    params
      (list author:login)))


(cl-json:decode-json-from-string (drakma:http-request "https://api.github.com/repos/Wolfgang3/VacationLabs_exercises/commits?since=2016-03-04&until=2016-03-07&per_page=100&access_token=9640b1ee872d669e33b4fd7e8166d17bf699ff9e"))


(defparameter *asana* (cl-json:decode-json-from-string (drakma:http-request "https://app.asana.com/api/1.0/projects/113203241574212/tasks?access_token=0/af8d04325c718270be55efe98be24869&completed_since=now&opt_pretty&opt_fields=name,completed_at")))



(jsown:val (car (jsown:val (jsown:parse (drakma:http-request "https://app.asana.com/api/1.0/projects/113203241574212/tasks?access_token=0/af8d04325c718270be55efe98be24869&completed_since=now&opt_pretty&opt_fields=name,completed_at")) "data")) "id")


(defparameter *k* (loop for rec in  (cdr (second *list*)) do
      (format t "~s " (jsown:val rec "id"))))


;in :obj form
(defparameter *list*  (jsown:parse (drakma:http-request "https://app.asana.com/api/1.0/projects/113203241574212/tasks?access_token=0/af8d04325c718270be55efe98be24869&completed_since=now&opt_pretty&opt_fields=name,completed_at")))


;; get the list of ids
(defparameter *id-list* nil)

(defun get-tasks-ids ()
  (with-input-from-string (s (drakma:http-request "https://app.asana.com/api/1.0/projects/113203241574212/tasks?access_token=0/af8d04325c718270be55efe98be24869&completed_since=2016-04-18T05:30:00Z&opt_pretty&opt_fields=name,modified_at,completed_at"))
    (let ((data (json:decode-json s)))
      ;(format t "~a~%"  data)
       (loop for rec in (rest (assoc :data data))
	  do
	   
	    (setf *id-list* (append *id-list* (list (rest (car rec)))))
	    )
       (format t "~a" *id-list*))))

;; ++++++++++++++++++++++++++ main ++++++++++++++++++++++++++
;;;;; get the task ids within start and end date
(defvar *str-date*)
(defvar *end-date*)
(defvar *completed-tasks-id*)
(defparameter *asana-api-tasks* "https://app.asana.com/api/1.0/projects/113203241574212/tasks")

(defvar *asana-token* "0/af8d04325c718270be55efe98be24869")

;;=> to convert the given time into a timstemp 
(setf *str-date* (local-time:format-timestring nil (local-time:parse-timestring "2016-04-18")))
(setf *end-date* (local-time:format-timestring nil (local-time:parse-timestring "2016-04-21")))

;(local-time:to-rfc3339-timestring (local-time:format-rfc3339-timestring nil "2013-12-01T05:30:00+05:30"))

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



