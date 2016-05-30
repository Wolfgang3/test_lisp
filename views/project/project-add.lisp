(in-package :mypackage)

(push (create-regex-dispatcher "^/project/add" 'project-add) *dispatch-table*)
(push (create-regex-dispatcher "^/project/project-form-check" 'project-form-check) *dispatch-table*)

(push (create-regex-dispatcher "^/project/[0-9]+/delete" 'project-delete) *dispatch-table*)

;; release-note form
(defun project-add (&key with-warning)
  (standard-page
    (:title "Create new project")
    (:div :class "row"
      (:div :class "col-sm-3 col-md-3")
      (:div :class "col-sm-6 col-md-6"
        (when with-warning (fmt "<b style=\"color:red\">~a</b>" with-warning))
        (:form  :action "/project/project-form-check" :method :post   
          (:div :class "form-group"
            (:label "Project Name: ")
            (:input :class "form-control" :type :text :name "name" :placeholder "Project Name" :required "true"))
      
          (:div :class "form-group"
            (:label "Git Token: ")
            (:input :class "form-control" :type :text :name "git-token" :placeholder "Git Token" :required "true"))
      
          (:div :class "form-group"
            (:label "Asana Token: ")
            (:input :class "form-control" :type :text :name "asana-token" :placeholder "Asana Token" :required "true"))
            
        (:input :class "btn btn-primary" :type "submit" :value "Create")))
      (:div :class "col-sm-3 col-md-3"))))

(defun project-form-check ()
  (let ((projnm (hunchentoot:post-parameter "name"))
  (git_tok (hunchentoot:post-parameter "git-token"))
  (asana_tok (hunchentoot:post-parameter "asana-token")))
    (if (eq (git-token-check git_tok) 'false)
  (project-add :with-warning "invalid git token")
  (if (eq (asana-token-check asana_tok) 'false)
      (project-add :with-warning "invalid asana token")
      (add-project-save projnm git_tok asana_tok)))))

;; to save the project in the db after the validation
(defun add-project-save (projnm git_tok asana_tok)
  (defparameter *project* (make-instance 'project :user-id (get-user) :name projnm :git-token git_tok :asana-token asana_tok))
  (insert-dao *project*)
  (save-object-list (get-all-repos :project-obj *project*))
  (save-object-list (get-all-asana-projects :selected-project-id (project-id *project*)))
  (redirect "/project")
  )

;;check if the git token is valid of invalid
(defun git-token-check (token)
  (let ((status (nth-value 1 (drakma:http-request "https://api.github.com/user"
                  :parameters (list (cons "access_token" token))))))
    (if (eq status 200)
  (return-from git-token-check 'true)
  (return-from git-token-check 'false))))


;;check if the asana token is valid or invalid
(defun asana-token-check (token)
  (let ((status (nth-value 1 (drakma:http-request "https://app.asana.com/api/1.0/users/me"
                  :parameters (list (cons "access_token" token))))))
    (if (eq status 200)
  (return-from asana-token-check 'true)
  (return-from asana-token-check 'false))))
