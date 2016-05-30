(in-package :mypackage)

(push (create-regex-dispatcher "^/project/[0-9]+/edit" 'project-edit) *dispatch-table*)
(push (create-regex-dispatcher "^/project/[0-9]+/project-edit-form-check" 'project-edit-form-check) *dispatch-table*)

(defun project-edit (&key with-warning)
  (let* ((proj-id (get-project-id-from-uri))
        (proj-obj (get-dao 'project proj-id)))
    (standard-page
      (:title "Create new project")
      (:div :class "row"
        (:div :class "col-sm-3 col-md-3")
        (:div :class "col-sm-6 col-md-6"
          (when with-warning (format s "<b style=\"color:red\">~a</b>" with-warning))
          (:form  :action "project-edit-form-check" :method :post   
            (:div :class "form-group"
              (:label "Project Name: ")
              (:input :class "form-control" :type :text :name "name" :value (project-name proj-obj) :required "true"))
        
            (:div :class "form-group"
              (:label "Git Token: ")
              (:input :class "form-control" :type :text :name "git-token" :value (project-git-token proj-obj) :required "true"))
        
            (:div :class "form-group"
              (:label "Asana Token: ")
              (:input :class "form-control" :type :text :name "asana-token" :value (project-asana-token proj-obj) :required "true"))
              
          (:input :class "btn btn-primary" :type "submit" :value "Update")))
        (:div :class "col-sm-3 col-md-3")))))


(defun project-edit-form-check ()
  (let ((projnm (hunchentoot:post-parameter "name"))
        (git_tok (hunchentoot:post-parameter "git-token"))
        (asana_tok (hunchentoot:post-parameter "asana-token")))
    (if (eq (git-token-check git_tok) 'false)
  (project-edit :with-warning "invalid git token")
  (if (eq (asana-token-check asana_tok) 'false)
      (project-edit :with-warning "invalid asana token")
      (edit-project-save projnm git_tok asana_tok)))))

(defun edit-project-save (projnm git_tok asana_tok)
  (let* ((proj-id (get-project-id-from-uri))
         (proj-obj (get-dao 'project proj-id)))
    (query (:update 'project :set 'name projnm 'git_token git_tok 'asana_token asana_tok :where (:= 'id proj-id)))
    (query (:delete-from 'git_repo :where (:= 'project_id proj-id)))
    (query (:delete-from 'asana_project :where (:= 'project_id proj-id)))
    (save-object-list (get-all-repos :project-obj proj-obj))
    (save-object-list (get-all-asana-projects :selected-project-id proj-id))
    (redirect "/project")
    ))