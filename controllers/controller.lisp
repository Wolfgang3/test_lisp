(in-package :mypackage)
;;=> to convert the date in a correct format (ISO-8601)(for asana api)
(defun convert-date (stamp)
  (local-time:format-timestring nil
     (local-time::parse-timestring stamp) :format '((:year 4) "-" (:month 2) "-" (:day 2) "T" (:hour 2) ":" (:min 2) ":" (:sec 2) "Z")))

;; save all the object in db present present in list
(defun save-object-list (list_name) 
    (loop for rec in list_name
       do
   (insert-dao rec)))

;; get-repo-list-of-project (return projects repo list)
(defun get-repo-list-of-project (&key project-obj)
  (return-from get-repo-list-of-project  (query (:select 'id 'repo-name :from 'git_repo :where (:= 'project-id (project-id project-obj))))))

(defun get-asana-proj-list-of-project (&key project-obj)
  (return-from get-asana-proj-list-of-project  (query (:select 'id 'asana-project-name :from 'asana_project :where (:= 'project-id (project-id project-obj))))))

(defun get-commits-of-repo-id (&key repo-id)
  (return-from get-commits-of-repo-id (query (:select 'id 'message :from 'commit :where (:= 'git-repo-id repo-id))))
  )

;; return timstamp from the univeral time (universal time is a bigint)
(defun convert-univeral-time-to-timestamp (sp)
  (let* ((yr (local-time:timestamp-year (local-time:universal-to-timestamp sp)))
   (m (local-time:timestamp-month (local-time:universal-to-timestamp sp)))
   (d (local-time:timestamp-day (local-time:universal-to-timestamp sp)))
   (date (format nil "~4,'0d-~2,'0d-~2,'0d" yr m d)))
    (return-from convert-univeral-time-to-timestamp date)))