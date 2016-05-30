(in-package :mypackage)

(push (create-regex-dispatcher "^/user-signup" 'user-signup-form) *dispatch-table*)
(push (create-regex-dispatcher "^/user-signup-save" 'user-save) *dispatch-table*)

(defun user-signup-form ()
  (standard-page
    (:title "User SignUp")
    (:div :class "row"
      (:div :class "col-sm-3 col-md-3")
      (:div :class "col-sm-6 col-md-6"
	 (:form  :action "/user-signup-save" :method :post	 
            (:div :class "form-group"
             (:label "Full Name: ")
             (:input :class "form-control" :type :text :name "name" :placeholder "Fullname" :required "true"))
	    
	    (:div :class "form-group"
             (:label "Email Id: ")
             (:input :class "form-control" :type :email :name "email" :placeholder "Email id" :required "true"))
	    
            (:div :class "form-group"
             (:label "Password: ")
             (:input :class "form-control" :type :password :name "pass" :placeholder "Password" :required "true"))
            
	    (:input :class "btn btn-primary" :type "submit" :value "Signup")))
      (:div :class "col-sm-3 col-md-3"))
    ))

;; save user in the db
(defun user-save ()
  (let* ((name (hunchentoot:post-parameter "name"))
	 (email (hunchentoot:post-parameter "email"))
	 (pass (hunchentoot:post-parameter "pass")))
    (insert-dao (make-instance 'users :name name :email-id email :password pass))
    (redirect "/user-login")
    ))

