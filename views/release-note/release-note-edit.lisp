(in-package :mypackage)

(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/edit" 'release-notes-edit) *dispatch-table*)
(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/edit-save" 'release-notes-edit-save) *dispatch-table*)

(defun release-notes-edit ()
  (let* ((release-id (get-release-id-from-uri))
        (release-obj (get-dao 'release-note release-id)))
  (standard-page
    (:title "Edit the Release Notes")
    (:div :class "container release-note-form"
     (:form  :action "edit-save" :method :post  
      (:div :class "row"
        (:div :class "col-md-1")
        (:div :style "text-align:left"  :class "col-md-10"
          (:div :class "row"  
            (:span :style "font-size:24px;" "Release note title:")
          (:input :type :text :style "font-size:16px;" :name "title" :placeholder "Enter title name" :value (release-note-title release-obj) :required "true"))
          (:div :class "row"
            (:h3 "Select the dates:")
            (:div :class "col-md-6"
              (:label "Start date:")
              (:input :type :text :name "start-date" :id "start-date" :value (convert-univeral-time-to-timestamp (release-note-start-date release-obj)) :required "true"))
            (:div :class "col-md-6"
              (:label "End date:")
              (:input :type :text :name "end-date" :id "end-date" :value (convert-univeral-time-to-timestamp (release-note-end-date release-obj)) :required "true")))
          (:br)
          (:div :class "row"  
            (:div :class "col-md-6"
              (:h3 :style "text-shadow: black 1px 4px 6px;text-align:center;color:blue;" "Select Git repos")  
                (:div :class "well" :style "height:300px;overflow: auto;"
           (:ul :class "list-group checked-list-box"
           (get-repo-list-checkboxes))))
            (:div :class "col-md-6"
              (:h3 :style "text-shadow: black 1px 4px 6px;text-align:center;color:blue;" "Select Asana projects")
                (:div :class "well" :style "height:300px;overflow: auto;"
           (:ul :class "list-group checked-list-box"
          (get-asana-project-checkboxes)))))
          (:br)
          (:div :class "row" :style "text-align: center;"
           (:div :class "col-md-12"  
            (:input :id "fetch" :style "font-size: 16px" :class "btn btn-primary" :type "submit" :name "submit" :value "Fetch")))
        )
              (:div :class "col-md-1")))))))

(defun release-notes-edit-save ()
  (let* ((proj-id (get-project-id-from-uri))
         (release-id (get-release-id-from-uri))
   (title (hunchentoot:post-parameter "title"))
   (str-date (hunchentoot:post-parameter "start-date"))
   (end-date (hunchentoot:post-parameter "end-date"))
   (release-id (query (:update 'release_note :set 'project_id proj-id 'title title 'start_date str-date 'end_date end-date :where (:= 'id release-id))))
   (parameter (hunchentoot:post-parameters*))
   (repo-id-checked (get-checkboxes-ids 'repo-checkboxes parameter))
   (asana-project-id-checked (get-checkboxes-ids 'asana-checkboxes parameter)))  
    ;; save all the commits and pr's
    (loop for id in repo-id-checked
       do
   (save-object-list (get-git-commits :selected-repo-id id :release-id release-id :token (project-git-token (get-dao 'project proj-id))))
   (save-object-list (get-pull-requests :selected-repo-id id :release-id release-id :token (project-git-token (get-dao 'project proj-id)))))
    ;; save all the tasks
    (loop for id in asana-project-id-checked
       do
   (save-object-list (get-asana-tasks :selected-asana-project-id id :release-id release-id :token (project-asana-token (get-dao 'project proj-id)))))
    ;; now the content will be generated
    (make-content-of-everything :release-id release-id)
    
    (redirect (concatenate 'string "/project/" proj-id "/release-note/" (write-to-string release-id) "/view" ))
    ))