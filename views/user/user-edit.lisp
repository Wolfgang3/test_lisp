(in-package :mypackage)

(push (create-regex-dispatcher "^/user-edit" 'user-edit-form) *dispatch-table*)
(push (create-regex-dispatcher "^/user-edit-save" 'user-edit-save) *dispatch-table*)

(defun user-edit-form ()
  (let* ((user-id (get-user))
        (user-obj (get-dao 'users user-id)))
  (standard-page
    (:title "Edit User")
    (:div :class "row"
      (:div :class "col-sm-3 col-md-3")
      (:div :class "col-sm-6 col-md-6"
   (:form  :action "/user-edit-save" :method :post   
            (:div :class "form-group"
             (:label "Full Name: ")
             (:input :class "form-control" :type :text :name "name" :placeholder "Fullname" :value (users-name user-obj) :required "true"))
      
      (:div :class "form-group"
             (:label "Email Id: ")
             (:input :class "form-control" :type :email :name "email" :placeholder "Email id" :value (users-email-id user-obj) :required "true"))
      
            (:div :class "form-group"
             (:label "Password: ")
             (:input :class "form-control" :type :text :name "pass" :placeholder "Password" :value (users-password user-obj) :required "true"))
            
      (:input :class "btn btn-primary" :type "submit" :value "Edit")))
      (:div :class "col-sm-3 col-md-3"))
    )))

;; save user in the db
(defun user-edit-save ()
  (let* ((name (hunchentoot:post-parameter "name"))
         (email (hunchentoot:post-parameter "email"))
         (pass (hunchentoot:post-parameter "pass")))
    (query (:update 'users :set 'name name 'email_id email 'password pass :where (:= 'id (get-user))))
    (redirect "/index")
    ))