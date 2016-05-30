;;;;;;;;;;;;;;; (CLOS)defclass procedure of tables ;;;;;;;;;;;;;;
;; users class
(in-package :mypackage)

(defclass users ()
  ((id :col-type serial :initarg :id
      :reader users-id)
   (name :col-type (varchar 30) :initarg :name
   :reader users-name)
   (email-id :col-type string :initarg :email-id
       :reader users-email-id)
   (password :col-type (varchar 30) :initarg :password
       :reader users-password))
  (:metaclass dao-class)
  (:keys id))

;; project class
(defclass project ()
  ((id :col-type serial :initarg :id
         :reader project-id)
   (user-id :col-type integer :initarg :user-id
      :reader project-user-id)
   (name :col-type (varchar 30) :initarg :name
   :reader project-name)
   (git-token :col-type string :initarg :git-token
        :reader project-git-token)
   (asana-token :col-type string :initarg :asana-token
    :reader project-asana-token)
   (created-date :col-type (or db-null timestamp) :col-default (current_timestamp 2)   
    :initarg :created-date
    :reader project-created-date))
  (:metaclass dao-class)
  (:keys id))

(deftable project
   (!dao-def)
   (!foreign 'users 'user-id 'id :on-delete :CASCADE :on-update :CASCADE))

;; release-note class
(defclass release-note ()
  ((id :col-type serial :initarg :id
         :reader release-note-id)
   (project-id :col-type integer :initarg :project-id
         :reader release-note-project-id)
   (title :col-type (varchar 30) :initarg :title
    :reader release-note-title)
   (start-date :col-type date :initarg :start-date
         :reader release-note-start-date)
   (end-date :col-type date :initarg :end-date
       :reader release-note-end-date)
   (created_date :col-type (or db-null timestamp) :col-default (current_timestamp 2) 
     :initarg :created_date
     :reader release-note-created_date))
  (:metaclass dao-class)
  (:keys id))

(deftable release-note
   (!dao-def)
   (!foreign 'project 'project_id 'id :on-delete :CASCADE :on-update :CASCADE))

;; git-repo class
(defclass git-repo ()
  ((id :col-type serial :initarg :id
    :reader git-repo-id)
   (project-id :col-type integer :initarg :project-id
         :reader git-repo-project-id)
   (repo-name :col-type (varchar 90) :initarg :repo-name
        :reader git-repo-repo-name))
  (:metaclass dao-class)
  (:keys id))

(deftable git-repo
   (!dao-def)
   (!foreign 'project 'project-id 'id :on-delete :CASCADE :on-update :CASCADE))

;; commit class
(defclass commit ()
  ((id :col-type serial :initarg :id
   :reader commit-id)
   (git-repo-id :col-type integer :initarg :git-repo-id
    :reader commit-git-repo-id)
   (release-id :col-type integer :initarg :release-id
         :reader commit-release-id)
   (message :col-type (varchar 80) :initarg :message
      :reader commit-message)
   (sha-key :col-type (varchar 60) :initarg :sha-key
      :reader commit-sha-key)
   (date :col-type timestamp :initarg :date
   :reader commit-date)
   (committed-by :col-type (varchar 80) :initarg :committed-by
   :reader commit-committed-by)
   (committer-avatar :col-type string :initarg :committer-avatar
   :reader commit-committer-avatar)
   (web-link :col-type string :initarg :web-link
   :reader commit-web-link))
  (:metaclass dao-class)
  (:keys id))

(deftable commit
   (!dao-def)
   (!foreign 'git-repo 'git-repo-id 'id :on-delete :CASCADE :on-update :CASCADE)
   (!foreign 'release-note 'release-id 'id :on-delete :CASCADE :on-update :CASCADE))


;; asana-project table
(defclass asana-project ()
  ((id :col-type serial :initarg :id
    :reader asana-project-id)
   (project-id :col-type integer :initarg :project-id
         :reader asana-project-project-id)
   (asana-project-id :col-type (varchar 30) :initarg :asana-project-id
         :reader asana-project-main-id)
   (asana-project-name :col-type (varchar 90) :initarg :asana-project-name
         :reader asana-project-name))
  (:metaclass dao-class)
  (:keys id))

(deftable asana-project
   (!dao-def)
   (!foreign 'project 'project-id 'id :on-delete :CASCADE :on-update :CASCADE))


;; task table
(defclass task ()
  ((id :col-type serial :initarg :id
   :reader task-id)
   (asana-project-id :col-type integer :initarg :asana-project-id
    :reader task-asana-project-id)
   (release-id :col-type integer :initarg :release-id
         :reader task-release-id)
   (asana-task-id :col-type (varchar 60) :initarg :asana-task-id
      :reader task-asana-task-id)
   (name :col-type (varchar 60) :initarg :name
   :reader task-name)
   (assignee-id :col-type (varchar 60) :initarg :assignee-id
    :reader task-assignee-id)
   (completed-at :col-type timestamp :initarg :completed-at
     :reader task-completed-at)
   (completed-by :col-type (varchar 80) :initarg :completed-by
     :reader task-completed-by)
   (description :col-type string :initarg :description
     :reader task-description)
   (web-link :col-type string :initarg :web-link
     :reader task-web-link))
  (:metaclass dao-class)
  (:keys id))

(deftable task
   (!dao-def)
   (!foreign 'release-note 'release-id 'id :on-delete :CASCADE :on-update :CASCADE)
   (!foreign 'asana-project 'asana-project-id 'id :on-delete :CASCADE :on-update :CASCADE))


;; pull-request table
(defclass pull-request ()
  ((id :col-type serial :initarg :id
   :reader pull-request-id)
   (git-repo-id :col-type integer :initarg :git-repo-id
    :reader pull-request-git-repo-id)
   (release-id :col-type integer :initarg :release-id
         :reader pull-request-release-id)
   (pull-request-id :col-type integer :initarg :pull-request-id
        :reader pull-request-main-id)
   (title :col-type (varchar 60) :initarg :title
    :reader pull-request-title)
   (date :col-type timestamp :initarg :date
   :reader pull-request-date)
   (created-by :col-type (varchar 80) :initarg :created-by
   :reader pull-request-created-by)
   (creator-avatar :col-type string :initarg :creator-avatar 
   :reader pull-request-creator-avatar )
   (web-link :col-type string :initarg :web-link
   :reader pull-request-web-link))
  (:metaclass dao-class)
  (:keys id))

(deftable pull-request
   (!dao-def)
   (!foreign 'git-repo 'git-repo-id 'id :on-delete :CASCADE :on-update :CASCADE)
   (!foreign 'release-note 'release-id 'id :on-delete :CASCADE :on-update :CASCADE))

;; section table
(defclass section ()
  ((id :col-type serial :initarg :id
     :reader section-id)
   (release-id :col-type integer :initarg :release-id
         :reader section-release-id)
   (sec-title :col-type (varchar 60) :initarg :sec-title
        :reader section-sec-title))
  (:metaclass dao-class)
  (:keys id))

(deftable section
   (!dao-def)
   (!foreign 'release-note 'release-id 'id :on-delete :CASCADE :on-update :CASCADE))


;; content table
(defclass content ()
  ((id :col-type serial :initarg :id
         :reader content-id)
   (release-id :col-type integer :initarg :release-id
         :reader content-release-id)
   (commit-id :col-type (or db-null integer) :initarg :commit-id
         :reader content-commit-id)
   (pull-request-id :col-type (or db-null integer) :initarg :pull-request-id
         :reader content-pull-request-id)
   (task-id :col-type (or db-null integer) :initarg :task-id
         :reader content-task-id)
   (section-id :col-type (or db-null integer) :initarg :section-id
     :reader content-section-id)
   (title :col-type (or db-null (varchar 80)) :initarg :title
    :reader content-title)
   (description :col-type (or db-null string) :initarg :description
    :reader content-description)
   (completed-date :col-type timestamp :initarg :completed-date
     :reader content-completed-date)
   (added-date :col-type (or db-null timestamp) :col-default (current_timestamp 2) 
         :initarg :added-date
         :reader content-added-date)
   (deleted :col-type (or db-null boolean) :col-default "false" 
         :initarg :deleted
         :reader content-deleted))
  (:metaclass dao-class)
  (:keys id))

(deftable content
   (!dao-def)
   (!foreign 'release-note 'release-id 'id :on-delete :CASCADE :on-update :CASCADE)
   (!foreign 'commit 'commit-id 'id :on-delete :CASCADE :on-update :CASCADE)
   (!foreign 'pull-request 'pull-request-id 'id :on-delete :CASCADE :on-update :CASCADE)
   (!foreign 'task 'task-id 'id :on-delete :CASCADE :on-update :CASCADE)
   (!foreign 'section 'section-id 'id :on-delete :CASCADE :on-update :CASCADE))

;; the final edited release note table
(defclass release-section-content ()
  ((id :col-type serial :initarg :id
         :reader release-section-content-id)
   (release-id :col-type integer :initarg :release-id
         :reader release-section-content-release-id)
   (content-id :col-type integer :initarg :commit-id
         :reader release-section-content-contenttableid)
   (section-id :col-type integer :initarg :section-id
     :reader release-section-content-sectiontableid)
   (newtitle :col-type (varchar 80) :initarg :newtitle
    :reader release-section-content-newtitle)
   (description :col-type (or db-null string) :initarg :description
    :reader release-section-content-description)
   (completed-date :col-type timestamp :initarg :completed-date
     :reader release-section-content-completed-date)
   (added-date :col-type (or db-null timestamp) :col-default (current_timestamp 2) 
         :initarg :added-date
         :reader release-section-content-added-date))
  (:metaclass dao-class)
  (:keys id))

(deftable release-section-content
   (!dao-def)
   (!foreign 'release-note 'release-id 'id :on-delete :CASCADE :on-update :CASCADE)
   (!foreign 'content 'content-id 'id :on-delete :NO-ACTION :on-update :NO-ACTION)
   (!foreign 'section 'section-id 'id :on-delete :CASCADE :on-update :CASCADE))

;;;;;;;;;;;;;; end of class def ;;;;;;;;;;;;;;;;;


;;add table definition
(dao-table-definition 'users)
(dao-table-definition 'project)
(dao-table-definition 'release-note)
(dao-table-definition 'git-repo)
(dao-table-definition 'commit)
(dao-table-definition 'asana-project)
(dao-table-definition 'task)
(dao-table-definition 'pull-request)
(dao-table-definition 'section)
(dao-table-definition 'content)
(dao-table-definition 'release-section-content)

;; to add tables in the db
(execute (dao-table-definition 'users))
(create-table 'project)
(create-table 'release-note)
(create-table 'git-repo)
(create-table 'commit)
(create-table 'asana-project)
(create-table 'task)
(create-table 'pull-request)
(create-table 'section)
(create-table 'content)
(create-table 'release-section-content)