(in-package :mypackage)
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

;;+++++++++++++++++++++++json creation to be fetched from angular +++++++++++++++++++++++++++

;; end points of the angular http call
(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/insertsection" 'insert-section) *dispatch-table*)

;; cut content angular end point
(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/check-content" 'check-content-deleted) *dispatch-table*)
(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/cut-content" 'cut-content) *dispatch-table*)
(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/uncut-content" 'uncut-content) *dispatch-table*)

;; =====> insert sections in the main content
(defun insert-section (&key title)
  (if (eq title nil)
    (return-from insert-section "")
    )
  (let* ((id (car (car (query (:insert-into 'section :set 'release_id (get-release-id-from-uri) 'sec_title title :returning 'id))))))
    (standard-page
    (:title "Add section")
    (:h2 (fmt "~a" id))
    )
    (return-from insert-section (write-to-string id))))

(defun delete-section (&key delete-section-id)
  (if (eq delete-section-id nil)
    (return-from delete-section "")
    )
  (query (:delete-from 'section :where (:= 'id  delete-section-id)))
  (return-from delete-section "done"))

(defun check-content-deleted ()
  (let* ((content-id (hunchentoot:get-parameter "content-id"))
         (obj (get-dao 'content content-id))
         (output (content-deleted obj)))
      (return-from check-content-deleted (write-to-string output))
    ))

(defun cut-content ()
  (let* ((content-id (hunchentoot:get-parameter "content-id")))
    (standard-page
     (:title "Cut content")
      (:h2 (fmt "~a" (query (:update 'content :set 'deleted "true" :where (:= 'id content-id)))))
      )))

(defun uncut-content ()
  (let* ((content-id (hunchentoot:get-parameter "content-id")))
    (standard-page
     (:title "Cut content")
      (:h2 (fmt "~a" (query (:update 'content :set 'deleted "false" :where (:= 'id content-id)))))
      )))

;; 
(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/fetch-release-note-json" 'endpoint-get-release-note) *dispatch-table*)

(defun endpoint-get-release-note ()
  (let* ((release-id (hunchentoot:get-parameter "releaseid"))
         (release-obj (get-dao 'release-note release-id))
         (proj-id (car (car (query (:select 'project_id :from 'release_note :where (:= 'id release-id ))))))
         (proj-obj (get-dao 'project proj-id))
         (content-list (get-objs-list-from-query :table 'content :foreign-key-name 'release-id :foreign-key-id release-id))
         (content-commit-list (get-data-list-from-content :content-list content-list :which-content 'commits))
         (content-pr-list (get-data-list-from-content :content-list content-list :which-content 'pull-requests))
         (content-task-list (get-data-list-from-content :content-list content-list :which-content 'tasks))   
         (section-list (get-objs-list-from-query :table 'section :foreign-key-name 'release-id :foreign-key-id release-id))
        )

  ;(format t "~a" (construct-commit-json content-commit-list))
  (return-from endpoint-get-release-note (concatenate 'string (format nil "{\"release-note\":~a,\"project\":~a" 
                                        (json:encode-json-to-string release-obj)
                                        (json:encode-json-to-string proj-obj))

                                      ;(format nil "")
                                      (format nil ",\"content-commits\": [~a]" (construct-commit-json content-commit-list))
                                      (format nil ",\"content-prs\": [~a]" (construct-pr-json content-pr-list))
                                      (format nil ",\"content-tasks\": [~a]" (construct-task-json content-task-list))
                                      (format nil ",\"main-content\": [~a]" (construct-sections-json section-list))
                                      (format nil "}")))))

;(ENDPOINT-GET-RELEASE-NOTE)
(defvar *obj-list*)
(defun construct-commit-json (content-commit-list)
  (setf *obj-list* nil)
  (dolist (obj content-commit-list)
    (let* ((commit-table-id (content-commit-id obj))
          (commit-obj (get-dao 'commit commit-table-id))
          )
    (setf *obj-list* (concatenate 'string *obj-list* (format nil "{\"content_id\":~a,\"title\":\"~a\",\"description\":\"~a\",\"commited_on\":~a,\"deleted\":\"~a\",\"commiters_name\":\"~a\",\"commiters_avatar\":\"~a\",\"web_link\":\"~a\"}," 
                                      (content-id obj)
                                      (substitute #\SPACE #\Newline (content-title obj))
                                      (content-description obj)
                                      (content-completed-date obj)
                                      (content-deleted obj)
                                      (commit-committed-by commit-obj)
                                      (commit-committer-avatar commit-obj)
                                      (commit-web-link commit-obj))))
    ))
    (if (= (length *obj-list*) 0)
      (return-from construct-commit-json "")
    (return-from construct-commit-json (subseq *obj-list* 0 (1- (length *obj-list*))))))

(defun construct-pr-json (content-pr-list)
  (setf *obj-list* nil)
  (dolist (obj content-pr-list)
    (let* ((pr-table-id (content-pull-request-id obj))
          (pr-obj (get-dao 'pull-request pr-table-id))
          )
    (setf *obj-list* (concatenate 'string *obj-list* (format nil "{\"content_id\":~a,\"title\":\"~a\",\"description\":\"~a\",\"closed_date\":~a,\"deleted\":\"~a\",\"created_by\":\"~a\",\"creator_avatar\":\"~a\",\"web_link\":\"~a\"}," 
                                      (content-id obj)
                                      (substitute #\SPACE #\Newline (content-title obj))
                                      (content-description obj)
                                      (content-completed-date obj)
                                      (content-deleted obj)
                                      (pull-request-created-by pr-obj)
                                      (pull-request-creator-avatar pr-obj)
                                      (pull-request-web-link pr-obj))))
    ))
    (if (= (length *obj-list*) 0)
      (return-from construct-pr-json "")
    (return-from construct-pr-json (subseq *obj-list* 0 (1- (length *obj-list*))))))

(defun construct-task-json (content-task-list)
  (setf *obj-list* nil)
  (dolist (obj content-task-list)
    (let* ((task-table-id (content-task-id obj))
          (task-obj (get-dao 'task task-table-id))
          )
    (setf *obj-list* (concatenate 'string *obj-list* (format nil "{\"content_id\":~a,\"title\":\"~a\",\"description\":\"~a\",\"completed_date\":~a,\"deleted\":\"~a\",\"completed_by\":\"~a\",\"task_description\":\"~a\",\"web_link\":\"~a\"}," 
                                      (content-id obj)
                                      (substitute #\SPACE #\Newline (content-title obj))
                                      (content-description obj)
                                      (content-completed-date obj)
                                      (content-deleted obj)
                                      (task-completed-by task-obj)
                                      (task-description task-obj)
                                      (task-web-link task-obj))))
    ))
  (if (= (length *obj-list*) 0)
      (return-from construct-task-json "")
    (return-from construct-task-json (subseq *obj-list* 0 (1- (length *obj-list*))))))


(defun get-data-list-from-content (&key content-list which-content)
  (setf *obj-list* nil)
  (dolist (rn content-list)
    (cond ((eq which-content 'commits)
            (if  (not (eq (content-commit-id rn) ':null))
              (setf *obj-list* (append *obj-list* (list rn)))))
          ((eq which-content 'pull-requests)
            (if  (not (eq (content-pull-request-id rn) ':null))
              (setf *obj-list* (append *obj-list* (list rn))))
          )
          (t
            (if  (not (eq (content-task-id rn) ':null))
              (setf *obj-list* (append *obj-list* (list rn))))
            ))
    )
  (return-from get-data-list-from-content *obj-list*))

;;=======> get all the main release note section content
(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/main-content-json" 'endpoint-get-main-releasenotes-content) *dispatch-table*)

(defun endpoint-get-main-releasenotes-content ()

  (let* ((releaseid (hunchentoot:get-parameter "releaseid"))
         (title (hunchentoot:get-parameter "title")) 
         (contentid (hunchentoot:get-parameter "contentid"))
         (sectionid (hunchentoot:get-parameter "sectionid"))
         (newtitle (hunchentoot:get-parameter "newtitle"))
         (description (hunchentoot:get-parameter "description"))
         (sec-id (insert-section :title title))
         (delete-section-id (hunchentoot:get-parameter "delete_section"))
         (delete-section-status (delete-section :delete-section-id delete-section-id))
         (delete-section-content-id (hunchentoot:get-parameter "delete_section_content"))
         (delete-section-content-status (delete-content-in-release-notes :releaseSectionContent-id delete-section-content-id))
         (release_section_content (save-content-in-release-notes :releaseid releaseid :contentid contentid :sectionid sectionid :newtitle newtitle :description description))
         (section-list (get-objs-list-from-query :table 'section :foreign-key-name 'release-id :foreign-key-id releaseid))
    )

  (return-from endpoint-get-main-releasenotes-content (concatenate 'string (format nil "{")
                                      ;(format nil "")
                                      (format nil "\"main-content\": [~a]" (construct-sections-json section-list))
                                      (format nil "}")))
  ))


(defun construct-sections-json (section-list)
  (setf *obj-list* nil)
  (dolist (obj section-list)
    (let* ((section-table-id (section-id obj))
          (section-content-list (get-objs-list-from-query :table 'release-section-content :foreign-key-name 'section-id :foreign-key-id section-table-id))
          )
    (setf *obj-list* (concatenate 'string *obj-list* (format nil "{\"section_id\":~a,\"section_name\":\"~a\",\"data\":[~a]},"
                                      (section-id obj)
                                      (section-sec-title obj)
                                      (construct-section-content-json section-content-list))))
    ))
  (if (= (length *obj-list*) 0)
      (return-from construct-sections-json "")
      (return-from construct-sections-json (subseq *obj-list* 0 (1- (length *obj-list*))))
      ))

(defun construct-section-content-json (section-content-list)
  (setf *obj-list* nil)
  (dolist (obj section-content-list)
    (let* ((release-section-content-table-id (release-section-content-id obj))
           (content-table-id (release-section-content-contenttableid obj))
           (section-table-id (release-section-content-sectiontableid obj))
           (title (release-section-content-newtitle obj))
           (description (release-section-content-description obj))
           (date (release-section-content-completed-date obj))
           (added-date (release-section-content-added-date obj))
           )

    (setf *obj-list* (concatenate 'string *obj-list* (format nil "{\"release_section_content_id\":~a,\"content_id\":~a,\"section_id\":\"~a\",\"title\":\"~a\",\"description\":\"~a\",\"date\":~a,\"added-date\":~a}," 
                                      release-section-content-table-id
                                      content-table-id
                                      section-table-id
                                      title
                                      description
                                      date
                                      added-date
                                      )))
    ))
    (if (= (length *obj-list*) 0)
      (return-from construct-section-content-json (write-to-string ""))
      (return-from construct-section-content-json (subseq *obj-list* 0 (1- (length *obj-list*))))
      ))

;;=======> add content to section
(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/save-content-in-release-notes" 'save-content-in-release-notes) *dispatch-table*)

(defun save-content-in-release-notes (&key releaseid contentid sectionid newtitle description)
  (if (eq newtitle nil)
    (return-from save-content-in-release-notes "")
    )
  (let* ((date (content-completed-date (get-dao 'content contentid)))
         (formated-date (convert-univeral-time-to-timestamp date))
         (id (car (car (query (:insert-into 'release_section_content :set 'release_id releaseid 'section_id sectionid 'content_id contentid 'newtitle newtitle 'description description 'completed_date formated-date))))))
  (return-from save-content-in-release-notes (write-to-string id)) )
  )

(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/delete-content-in-release-notes" 'delete-content-in-release-notes) *dispatch-table*)

(defun delete-content-in-release-notes (&key releaseSectionContent-id)
  (if (eq releaseSectionContent-id nil)
    (return-from delete-content-in-release-notes "")
    )
  (query (:delete-from 'release-section-content :where (:= 'id  releaseSectionContent-id)))
  (return-from delete-content-in-release-notes "done"))