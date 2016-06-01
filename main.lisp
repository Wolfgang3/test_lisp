;;============== lisp project
;;=========== Generate Release notes
;;

(defparameter *project-path* "home/wolfgang/release_notes_lisp")

;; ===================>>>> includes
(load (make-pathname :directory *project-path* :name "set-up.asd"))
(ql:quickload :custom-library)

;; ================================

;; create a instance of user
(defparameter *user1* (make-instance 'users :name "wolfgang furtado" :email-id "wol@gmail.com" :password "Wolfgang3"))

(insert-dao *user1*)

;; create a instance of project
(defparameter *project1* (make-instance 'project :user-id (users-id *user1*) :name "project name one" :git-token "0db42a2a18ffbeb1714fa9f8a50e1b80578290a8" :asana-token "0/af8d04325c718270be55efe98be24869"))

(insert-dao *project1*)

;;++++++++++++++++ git
;;;;;;;; get and save all the repos in db  ;;;;;;;;;;
(save-object-list (get-all-repos :project-obj *project1*)) 

(defparameter *release-notes1* (make-instance 'release-note :project-id (project-id *project1*) :title "release title" :start-date "2016-04-02" :end-date "2016-04-29"))

(insert-dao *release-notes1*)

;; selected repo
(defparameter *selected-repo-id* (car (nth 0 (get-repo-list-of-project :project-obj *project1*))))

;;;;;;;; get and save all the commits in db  ;;;;;;;;;;
(save-object-list (get-git-commits :selected-repo-id *selected-repo-id* :release-id (release-note-id *release-notes1*) :token (project-git-token *project1*)))

;;;;;;;; get and save all the pull request in db  ;;;;;;;;;;
(save-object-list (get-pull-requests  :selected-repo-id *selected-repo-id* :release-id (release-note-id *release-notes1*) :token (project-git-token *project1*)))




;;++++++++++++++++  asana
(get-all-asana-workspaces :project-obj *project1*)

;select the workspace from the list of all workspaces
(defparameter *selected-workspace* (car (nth 0 (get-all-asana-workspaces :project-obj *project1*))))

;;;;;;;; get and save all the asana projects in db  ;;;;;;;;;;
(save-object-list (get-all-asana-projects :selected-project-id (project-id *project1*) :workspace-id *selected-workspace*))

;;after getting all projects, select one project to get its tasks
(defparameter *selected-asana-project* (car (nth 0 (get-asana-proj-list-of-project :project-obj *project1*))))

;;;;;;; get and sav all the task of the asana project ;;;;;;;;;
(save-object-list (get-asana-tasks :selected-asana-project-id *selected-asana-project* :release-id (release-note-id *release-notes1*) :token (project-asana-token *project1*)))

;; create section object
(defparameter *section1* (make-instance 'section :release-id (release-note-id *release-notes1*)  :sec-title "section 1" ))

(insert-dao *section1*)


;; make the content table
(defparameter *selected-release-note* (car (nth 0 (get-release-note-list-of-project :project-obj *project1*))))


;; (get-all-commits-obj-of-release-note :release-id *selected-release-note*)

;;make content of everything from pr's, commit and task
(make-content-of-everything :release-id *selected-release-note*)


;; add individual commit to the content
(defparameter *commit-object* (get-dao 'commit (car (nth 1 (get-commits-of-repo-id :repo-id *selected-repo-id*)))))

(add-to-content :which-id 'commit_id :id (commit-id *commit-object*) :release-id *selected-release-note* :title (commit-message *commit-object*) :description "this this this" :date (convert-univeral-time-to-timestamp (commit-date *commit-object*)))

(in-package :mypackage)
(format t "~a" (setf (project-name (get-dao 'project "1")) "tt"))

(format t "{\"first\":~a,\"second\":~a}" (json:encode-json-to-string *USER1*) (json:encode-json-to-string *USER1*) )

(jsown:to-json (jsown:new-js
                   ("items" nil)
                   ("falseIsEmptyList" :f)
                   ("success" t)))


(cl-json:encode-json-to-string
 (alexandria:plist-hash-table '("foo" 1 "bar" (json:encode-json *USER1*)) :test #'eq))


(jsown:to-json (jsown:new-js
                   ("items" (jsown:new-js
                   ("items" (cl-json:decode-json-from-string (json:encode-json-to-string *USER1*)))
                   ("falseIsEmptyList" :f)
                   ("success" t)))
                   ("falseIsEmptyList" :f)
                   ("success" t)))
(format nil "~s" (get-objs-list-from-query :table 'content :foreign-key-name 'release-id :foreign-key-id 1))

(ENDPOINT-GET-RELEASE-NOTE)
(content-task-id rn)

(remove #\/n "(content-
 title obj)")