(in-package :mypackage)

(push (create-regex-dispatcher "^/user-login" 'login-check) *dispatch-table*)
(push (create-regex-dispatcher "^/login-successful" 'login-successful) *dispatch-table*)

(defun user-login-form (&key with-warning)
  (standard-page
    (:title "User SignUp")
    (:div :class "row"
      (:div :class "col-sm-3 col-md-3")
      (:div :class "col-sm-6 col-md-6"
        (when with-warning (fmt "<b style=\"color:red\">Invalid password</b>"))
          (:form  :action "/user-login" :method :post         
            (:div :class "form-group"
             (:label "Email Id: ")
             (:input :class "form-control" :type :email :name "user-email" :placeholder "Email Id" :required "true"))
      
            (:div :class "form-group"
             (:label "Password: ")
             (:input :class "form-control" :type :password :name "user-pass" :placeholder "Password" :required "true"))
            
            (:input :class "btn btn-primary" :type "submit" :value "Login")))
      (:div :class "col-sm-3 col-md-3"))
    ))

(defun get-user ()
  (hunchentoot:session-value 'user_id))

(defun login-check ()
  (when (get-user)
    (redirect "/index"))
  (let ((usernm (hunchentoot:post-parameter "user-email"))
        (pass (hunchentoot:post-parameter "user-pass")))
    (if (and usernm pass)
  (multiple-value-bind (data n)
      (query (:select 'id :from 'users :where (:and (:= 'email_id usernm) (:= 'password pass))))
    (cond ((= n 0)
     (user-login-form :with-warning t))
    (t (set-cookie "user-id" :value (car (car data)))
       (hunchentoot:start-session)
       (setf (hunchentoot:session-value 'user_id) (car (car data)) )
       (redirect "/index"))
    ))
  (user-login-form ))))

(defun login-successful ()
  (standard-page
    (:title "login successful")
      
      (:h1 (fmt "successful"))
      (:h2 (fmt "cookie:user-id: ~a" (cookie-in "user-id")))
      (:h2 (fmt "session:user-id: ~a" (hunchentoot:session-value 'user_id)))
      
      (:h2 (fmt "~a" (get-user)))))
    
