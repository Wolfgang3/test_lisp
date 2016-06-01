(in-package :mypackage)

;; get all the repos from the project-obj ============================
;;  this creates instances of git-repo class
(defvar *obj-list*)

(defun get-all-repos (&key project-obj)
  (setf *obj-list* nil)
  (let* ((token (project-git-token project-obj))
  (json (jsown:parse
          (drakma:http-request "https://api.github.com/user/repos"
           :parameters (list (cons "access_token" token)
           (cons "per_page" "1000")
           (cons "sort" "created"))))))
    (loop for rec in json
       do
   (let* ((full-name (jsown:val (cdr rec) "full_name"))
         (instance (make-instance 'git-repo :project-id (project-id project-obj) :repo-name full-name)))
     (setf *obj-list* (append *obj-list* (list instance)))
     ))
  (return-from get-all-repos *obj-list*)
    ))
;; all the repos will be save in *obj-list*
;;===================================================================

;; get all the commits or the repos =================================

(defun get-git-commits (&key selected-repo-id release-id token)
  (setf *obj-list* nil)
  (let* ((repo-name (git-repo-repo-name (get-dao 'git-repo selected-repo-id)))
         (url (concatenate 'string "https://api.github.com/repos/" repo-name "/commits"))
         (start-date (convert-univeral-time-to-timestamp (release-note-start-date (get-dao 'release-note release-id))))
         (end-date (convert-univeral-time-to-timestamp (release-note-end-date (get-dao 'release-note release-id))))
         (json (jsown:parse
          (drakma:http-request url
           :parameters (list (cons "access_token" token)
                 (cons "since" (convert-date start-date))
                 (cons "until"(convert-date  end-date))
                 (cons "per_page" "100"))))))
    (loop for rec in json
       do
   (let* ((message (jsown:val (jsown:val  rec "commit") "message"))
    (sha (jsown:val  rec "sha"))
    (date (jsown:val (jsown:val (jsown:val  rec "commit") "committer") "date"))
    (committed-by (jsown:val (jsown:val rec "committer") "login"))
    (committer-avatar (jsown:val (jsown:val rec "committer") "avatar_url"))
    (web-link (jsown:val rec "html_url"))
    (instance (make-instance 'commit :git-repo-id selected-repo-id :release-id release-id :message message :sha-key sha :date date :committed-by committed-by :committer-avatar committer-avatar :web-link web-link)))
     (setf *obj-list* (append *obj-list* (list instance)))
     ))
    (return-from get-git-commits *obj-list*)
    ))
;;=================================================================

;; get all the pull request =======================================
(defun pr-date-check (closed-at start-date end-date)
  (and (local-time:timestamp< (local-time:parse-timestring closed-at) (local-time:parse-timestring end-date))
       (local-time:timestamp> (local-time:parse-timestring closed-at) (local-time:parse-timestring start-date)))  )


(defun get-pull-requests (&key selected-repo-id release-id token) 
  (setf *obj-list* nil)
  (let* ((repo-name (git-repo-repo-name (get-dao 'git-repo selected-repo-id)))
         (url (concatenate 'string "https://api.github.com/repos/" repo-name "/pulls"))
         (start-date (convert-univeral-time-to-timestamp (release-note-start-date (get-dao 'release-note release-id))))
         (end-date (convert-univeral-time-to-timestamp (release-note-end-date (get-dao 'release-note release-id))))
         (json (jsown:parse
          (drakma:http-request url
           :parameters (list (cons "access_token" token)
                 (cons "state" "closed")
                 (cons "per_page" "100"))))))
    (loop for rec in json
      do
       (if (eq (pr-date-check (jsown:val  rec "closed_at") start-date end-date) T)  
          (let* ((closed-at (jsown:val  rec "closed_at"))
                (pr-title (jsown:val  rec "title"))
                (pull-request-id (jsown:val  rec "number"))
                (created-by (jsown:val (jsown:val rec "user") "login"))
                (creator-avatar (jsown:val (jsown:val rec "user") "avatar_url"))
                (web-link (jsown:val rec "html_url"))
                (instance (make-instance 'pull-request :git-repo-id selected-repo-id :release-id release-id :pull-request-id pull-request-id :title pr-title :date closed-at :created-by created-by :creator-avatar creator-avatar :web-link web-link)))
          (setf *obj-list* (append *obj-list* (list instance)))
          )))
    (return-from get-pull-requests *obj-list*)
    ))
;; ================================================================