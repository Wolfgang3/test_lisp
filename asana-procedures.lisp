
;; get all asana workspaces
(defvar *obj-list*)
(defun get-all-asana-workspaces (&key project-obj)
  (setf *obj-list* nil)
  (let* ((asana-token (project-asana-token project-obj))
         (json (jsown:parse
          (drakma:http-request "https://app.asana.com/api/1.0/workspaces"
           :parameters (list (cons "access_token" asana-token))))))
    (loop for rec in (rest (car (cdr json)))
       do
       (let* ((workspace_id (jsown:val rec "id"))
              (workspace_name (jsown:val rec "name")))
           (setf *obj-list* (append *obj-list* (list (list workspace_id workspace_name))))
           ))
  (return-from get-all-asana-workspaces *obj-list*)))

;; get all asana projects from workspace ===========================
(defun get-all-asana-projects (&key selected-project-id workspace-id)
  (setf *obj-list* nil)
  (let* ((asana-token (project-asana-token (get-dao 'project selected-project-id)))
         (json (jsown:parse
             (drakma:http-request "https://app.asana.com/api/1.0/projects"
                   :parameters (list (cons "access_token" asana-token )
                         (cons "workspace" (write-to-string workspace-id)))))))
    (loop for rec in (rest (car (cdr json)))
      do
        (let* ((asana-project-id (jsown:val rec "id"))
              (asana-project-name (jsown:val rec "name"))
              (instance (make-instance 'asana-project :project-id selected-project-id :asana-project-id asana-project-id :asana-project-name asana-project-name)))
        (setf *obj-list* (append *obj-list* (list instance)))
        ))
    (return-from get-all-asana-projects *obj-list*)
    ))
;; =================================================================


;; get all asana tasks =============================================

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

(defun get-asana-tasks (&key selected-asana-project-id release-id token)
  (setf *obj-list* nil)
  (let* ((asana-project-main-id (asana-project-main-id (get-dao 'asana-project selected-asana-project-id)))
         (start-date (convert-univeral-time-to-timestamp (release-note-start-date (get-dao 'release-note release-id))))
         (end-date (convert-univeral-time-to-timestamp (release-note-end-date (get-dao 'release-note release-id)))))
    (loop for rec in (jsown:val (get-tasks-completed-since token asana-project-main-id start-date) "data")
       do
       (let* ((task-date (jsown:val rec "completed_at"))
              (task-name (jsown:val rec "name"))
              (task-id (jsown:val rec "id"))
              (assignee-obj (jsown:val rec "assignee")))
         (if (not (eq task-date NIL))
             (if (eq (is-task-date-less-then-end-date? task-date end-date) T)
          (setf *obj-list* (append *obj-list* 
                                   (list (make-instance 'task :ap-id selected-asana-project-id :release-id release-id :asana-task-id task-id :name task-name :assignee-id (jsown:val assignee-obj "id") :completed-at task-date))))))
        ))
    (return-from get-asana-tasks *obj-list*)
    ))
;; ================================================================
