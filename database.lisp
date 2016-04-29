;;;;;;;;;;;;;;; (CLOS)defclass procedure of tables ;;;;;;;;;;;;;;

;; system_user table
(defclass system_user ()
  ((user_id :col-type serial :initarg :user_id
	    :reader user_id)
   (name :col-type (varchar 30) :initarg :name
	 :reader system_user-name)
   (email_id :col-type string :initarg :email_id
	     :reader system_user-email_id)
   (password :col-type (varchar 30) :initarg :password
	     :reader system_user-password))
  (:metaclass dao-class)
  (:keys user_id))

(dao-table-definition 'system_user)
(execute (dao-table-definition 'system_user))

;; project table 
(defclass project ()
  ((project_id :col-type serial :initarg :project_id
	       :reader project_id)
   (user_id :col-type integer :initarg :user_id
	    :reader project-user_id)
   (name :col-type (varchar 30) :initarg :name
	 :reader project-name)
   (git_token :col-type string :initarg :git_token
	      :reader project-git_token)
   (asana_token :col-type string :initarg :asana_token
		:reader project-asana_token)
   (created_date :col-type (or db-null timestamp) :col-default (current_timestamp 2)   
		:initarg :created_date
		:reader project-created_date))
  (:metaclass dao-class)
  (:keys project_id))

(deftable project
   (!dao-def)
   (!foreign 'system_user 'user_id 'user_id :on-delete :NO-ACTION :on-update :NO-ACTION))

(dao-table-definition 'project)
(create-table 'project)

;; git_repo table
(defclass git_repo ()
  ((gr_id :col-type serial :initarg :gr_id
	  :reader gr_id)
   (project_id :col-type integer :initarg :project_id
	       :reader git_repo-project_id)
   (repo_name :col-type (varchar 30) :initarg :repo_name
	      :reader git_repo-repo_name))
  (:metaclass dao-class)
  (:keys gr_id))

(deftable git_repo
   (!dao-def)
   (!foreign 'project 'project_id 'project_id :on-delete :NO-ACTION :on-update :NO-ACTION))

(dao-table-definition 'git_repo)
(create-table 'git_repo)

;; asana_project table
(defclass asana_project ()
  ((ap_id :col-type serial :initarg :ap_id
	  :reader ap_id)
   (project_id :col-type integer :initarg :project_id
	       :reader asana_project-project_id)
   (asana_project_id :col-type (varchar 30) :initarg :asana_project_id
		     :reader asana_project-asana_project_id))
  (:metaclass dao-class)
  (:keys ap_id))

(deftable asana_project
   (!dao-def)
   (!foreign 'project 'project_id 'project_id :on-delete :NO-ACTION :on-update :NO-ACTION))

(dao-table-definition 'asana_project)
(create-table 'asana_project)

;; release_note table
(defclass release_note ()
  ((release_id :col-type serial :initarg :release_id
	       :reader release_id)
   (project_id :col-type integer :initarg :project_id
	       :reader release_note-project_id)
   (title :col-type (varchar 30) :initarg :title
	  :reader release_note-title)
   (start_date :col-type date :initarg :start_date
	       :reader release_note-start_date)
   (end_date :col-type date :initarg :end_date
	     :reader release_note-end_date)
   (created_date :col-type (or db-null timestamp) :col-default (current_timestamp 2) 
		 :initarg :created_date
		 :reader release_note-created_date))
  (:metaclass dao-class)
  (:keys release_id))

(deftable release_note
   (!dao-def)
   (!foreign 'project 'project_id 'project_id :on-delete :NO-ACTION :on-update :NO-ACTION))

(dao-table-definition 'release_note)
(create-table 'release_note)

;; commit table
(defclass commit ()
  ((c_id :col-type serial :initarg :c_id
	 :reader c_id)
   (gr_id :col-type integer :initarg :gr_id
	  :reader commit-gr_id)
   (release_id :col-type integer :initarg :release_id
	       :reader commit-release_id)
   (message :col-type (varchar 60) :initarg :message
	    :reader commit-message)
   (sha_key :col-type (varchar 60) :initarg :sha_key
	    :reader commit-sha_key)
   (date :col-type timestamp :initarg :date
	 :reader commit-date))
  (:metaclass dao-class)
  (:keys c_id))

(deftable commit
   (!dao-def)
   (!foreign 'git_repo 'gr_id 'gr_id :on-delete :NO-ACTION :on-update :NO-ACTION)
   (!foreign 'release_note 'release_id 'release_id :on-delete :NO-ACTION :on-update :NO-ACTION))

(dao-table-definition 'commit)
(create-table 'commit)


;; task table
(defclass task ()
  ((t_id :col-type serial :initarg :t_id
	 :reader t_id)
   (ap_id :col-type integer :initarg :ap_id
	  :reader task-ap_id)
   (release_id :col-type integer :initarg :release_id
	       :reader task-release_id)
   (asana_task_id :col-type (varchar 60) :initarg :asana_task_id
		  :reader task-asana_task_id)
   (name :col-type (varchar 60) :initarg :name
	 :reader task-name)
   (assignee_id :col-type (varchar 60) :initarg :assignee_id
		:reader task-assignee_id)
   (completed_at :col-type timestamp :initarg :completed_at
		 :reader task-completed_at))
  (:metaclass dao-class)
  (:keys t_id))

(deftable task
   (!dao-def)
   (!foreign 'release_note 'release_id 'release_id :on-delete :NO-ACTION :on-update :NO-ACTION)
   (!foreign 'asana_project 'ap_id 'ap_id :on-delete :NO-ACTION :on-update :NO-ACTION))

(dao-table-definition 'task)
(create-table 'task)

;; pull_request table
(defclass pull_request ()
  ((p_id :col-type serial :initarg :p_id
	 :reader p_id)
   (gr_id :col-type integer :initarg :gr_id
	  :reader pull_request-gr_id)
   (release_id :col-type integer :initarg :release_id
	       :reader pull_request-release_id)
   (pull_request_id :col-type integer :initarg :pull_request_id
		    :reader pull_request-pull_request_id)
   (title :col-type (varchar 60) :initarg :title
	  :reader pull_request-title)
   (date :col-type timestamp :initarg :date
	 :reader pull_request-date))
  (:metaclass dao-class)
  (:keys p_id))

(deftable pull_request
   (!dao-def)
   (!foreign 'git_repo 'gr_id 'gr_id :on-delete :NO-ACTION :on-update :NO-ACTION)
   (!foreign 'release_note 'release_id 'release_id :on-delete :NO-ACTION :on-update :NO-ACTION))

(dao-table-definition 'pull_request)
(create-table 'pull_request)

;; section table
(defclass section ()
  ((sec_id :col-type serial :initarg :sec_id
	   :reader sec_id)
   (release_id :col-type integer :initarg :release_id
	       :reader section-release_id)
   (sec_title :col-type (varchar 60) :initarg :sec_title
	      :reader section-sec_title))
  (:metaclass dao-class)
  (:keys sec_id))

(deftable section
   (!dao-def)
   (!foreign 'release_note 'release_id 'release_id :on-delete :NO-ACTION :on-update :NO-ACTION))

(dao-table-definition 'section)
(create-table 'section)

;; content table
(defclass content ()
  ((content_id :col-type serial :initarg :content_id
	       :reader content_id)
   (release_id :col-type integer :initarg :release_id
	       :reader content-release_id)
   (c_id :col-type integer :initarg :c_id
         :reader content-c_id)
   (p_id :col-type integer :initarg :p_id
         :reader content-p_id)
   (t_id :col-type integer :initarg :t_id
         :reader content-t_id)
   (sec_id :col-type integer :initarg :sec_id
	   :reader content-sec_id)
   (title :col-type (varchar 60) :initarg :title
	  :reader content-title)
   (description :col-type (varchar 60) :initarg :description
		:reader content-description)
   (added_date :col-type (or db-null timestamp) :col-default (current_timestamp 2) 
	       :initarg :added_date
	       :reader content-added_date))
  (:metaclass dao-class)
  (:keys content_id))

(deftable content
   (!dao-def)
   (!foreign 'release_note 'release_id 'release_id :on-delete :NO-ACTION :on-update :NO-ACTION)
   (!foreign 'commit 'c_id 'c_id :on-delete :NO-ACTION :on-update :NO-ACTION)
   (!foreign 'pull_request 'p_id 'p_id :on-delete :NO-ACTION :on-update :NO-ACTION)
   (!foreign 'task 't_id 't_id :on-delete :NO-ACTION :on-update :NO-ACTION)
   (!foreign 'section 'sec_id 'sec_id :on-delete :NO-ACTION :on-update :NO-ACTION))

(dao-table-definition 'content)
(create-table 'content)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
