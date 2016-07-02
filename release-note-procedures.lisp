(defvar *obj-list*)

;; get-release-note-list-of-project (return projects release-note list)
(defun get-release-note-list-of-project (&key project-obj)
  (return-from get-release-note-list-of-project  (query (:select 'id 'title :from 'release_note :where (:= 'project-id (project-id project-obj))))
  ))

;; get all the commits of a release-note
(defun get-all-commits-obj-of-release-note (&key release-id)
  (setf *obj-list* nil)
  (let ((id-list (query (:select 'id :from 'commit :where (:= 'release-id release-id)))))
    (loop for rec in id-list
      do
      (setf *obj-list* (append *obj-list* (list (get-dao 'commit (car rec))) )))
    (return-from get-all-commits-obj-of-release-note *obj-list*)))

;; get all the pull-requests of  a release-note
(defun get-all-pull-requests-obj-of-release-note (&key release-id)
  (setf *obj-list* nil)
  (let ((id-list (query (:select 'id :from 'pull-request :where (:= 'release-id release-id)))))
    (loop for rec in id-list
      do
      (setf *obj-list* (append *obj-list* (list (get-dao 'pull-request (car rec))) )))
    (return-from get-all-pull-requests-obj-of-release-note *obj-list*)))

;; get all the tasks of  a release-note
(defun get-all-tasks-obj-of-release-note (&key release-id)
  (setf *obj-list* nil)
  (let ((id-list (query (:select 'id :from 'task :where (:= 'release-id release-id)))))
    (loop for rec in id-list
      do
      (setf *obj-list* (append *obj-list* (list (get-dao 'task (car rec))) )))
    (return-from get-all-tasks-obj-of-release-note *obj-list*)))