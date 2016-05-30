(in-package :mypackage)

;; add object data to content
(defun add-all-object-data-to-content (&key release-id obj-list table-id id-method title-method date-method)
  (loop for rec in obj-list
    do
    (let* ((id (funcall id-method rec))
          (title (funcall title-method rec))
          (date (funcall date-method rec)))
      (add-to-content :which-id table-id :id id :release-id release-id :title title :description nil :date (convert-univeral-time-to-timestamp  date))
      )))

;; add the data to the content
(defun add-to-content (&key which-id id release-id title description date)
  (query (:insert-into 'content :set which-id id 'release_id release-id 'title title 'description description 'completed_date date))
  )

;; add all the commits, prs and tasks to content
(defun make-content-of-everything (&key release-id)
  (let ((commit-obj-list (get-all-commits-obj-of-release-note :release-id release-id))
        (pr-obj-list (get-all-pull-requests-obj-of-release-note :release-id release-id))
        (task-obj-list (get-all-tasks-obj-of-release-note :release-id release-id)))
  
  (add-all-object-data-to-content :release-id release-id :obj-list commit-obj-list :table-id 'commit_id :id-method 'commit-id :title-method 'commit-message :date-method 'commit-date)
  (add-all-object-data-to-content :release-id release-id :obj-list pr-obj-list :table-id 'pull_request_id :id-method 'pull-request-id :title-method 'pull-request-title :date-method 'pull-request-date)
  (add-all-object-data-to-content :release-id release-id :obj-list task-obj-list :table-id 'task_id :id-method 'task-id :title-method 'task-name :date-method 'task-completed-at)
  ))

