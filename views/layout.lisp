
(in-package :mypackage)

;images
(push (create-static-file-dispatcher-and-handler "/images/profile.jpg" "release_notes_lisp/images/profile.jpg") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/images/logo.png" "release_notes_lisp/images/logo.png") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/images/working.gif" "release_notes_lisp/images/working.gif") *dispatch-table*)
;; glyphicons fonts
(push (create-static-file-dispatcher-and-handler "/fonts/glyphicons-halflings-regular.ttf" "release_notes_lisp/bootstrap/fonts/glyphicons-halflings-regular.ttf") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/fonts/glyphicons-halflings-regular.woff" "release_notes_lisp/bootstrap/fonts/glyphicons-halflings-regular.woff") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/fonts/glyphicons-halflings-regular.woff2" "release_notes_lisp/bootstrap/fonts/glyphicons-halflings-regular.woff2") *dispatch-table*)
;;font awesome fonts
(push (create-static-file-dispatcher-and-handler "/fonts/fontawesome-webfont.woff2" "release_notes_lisp/font-awesome-4.6.1/fonts/fontawesome-webfont.woff2") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/fonts/fontawesome-webfont.woff " "release_notes_lisp/font-awesome-4.6.1/fonts/fontawesome-webfont.woff") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/fonts/fontawesome-webfont.ttf" "release_notes_lisp/font-awesome-4.6.1/fonts/fontawesome-webfont.ttf") *dispatch-table*)

(push (create-static-file-dispatcher-and-handler "/templates/release-notes-template.html" "release_notes_lisp/views/templates/release-notes-template.html") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/templates/section-data-template.html" "release_notes_lisp/views/templates/section-data-template.html") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/templates/content-list-template.html" "release_notes_lisp/views/templates/content-list-template.html") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/templates/extra-commit-template.html" "release_notes_lisp/views/templates/extra-commit-template.html") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/templates/extra-pull-request-template.html" "release_notes_lisp/views/templates/extra-pull-request-template.html") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/templates/extra-task-template.html" "release_notes_lisp/views/templates/extra-task-template.html") *dispatch-table*)


(push (create-static-file-dispatcher-and-handler "/bootstrap.css" "release_notes_lisp/bootstrap/css/bootstrap.css") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/font-awesome.css" "release_notes_lisp/font-awesome-4.6.1/css/font-awesome.css") *dispatch-table*)

(push (create-static-file-dispatcher-and-handler "/style.css" "release_notes_lisp/css/style.css") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/jquery-ui.css" "release_notes_lisp/css/jquery-ui.css") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/jquery.js" "release_notes_lisp/js/jquery-2.2.0.min.js") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/jquery-ui.js" "release_notes_lisp/js/jquery-ui.min.js") *dispatch-table*)

(push (create-static-file-dispatcher-and-handler "/bootstrap-js.js" "release_notes_lisp/bootstrap/js/bootstrap.js") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/script.js" "release_notes_lisp/js/script.js") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/angular-lib.js" "release_notes_lisp/angular/angular.js") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/angular-ui-router.js" "release_notes_lisp/angular/angular-ui-router.js") *dispatch-table*)
(push (create-static-file-dispatcher-and-handler "/angular.js" "release_notes_lisp/js/angular.js") *dispatch-table*)


;standard page for all the html pages
(defmacro standard-page ((&key title) &body body)
  `(cl-who:with-html-output-to-string (*standard-output* nil :prologue t :indent t)
     (:html
      (:head 
       (:meta :content "text/html" :charset "utf-8")
       (:meta :http-equiv "X-UA-Compatible" :content "IE=edge")
       (:meta :name "viewport" :content "width=device-width, initial-scale=1")
       (:title ,title)
       (:link :href "/style.css" :rel "stylesheet" :type "text/css")
       (:link :href "/bootstrap.css" :rel "stylesheet" :type "text/css")
       (:link :href "/font-awesome.css" :rel "stylesheet" :type "text/css")
       (:link :href "//code.jquery.com/ui/1.11.4/themes/smoothness/jquery-ui.css" :rel "stylesheet" :type "text/css")
       ;;(:link :rel "stylesheet" :href "http://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.4.0/css/font-awesome.min.css")
       
       (:script :src "/jquery.js" )
       (:script :src "/jquery-ui.js")
       (:script :src "/bootstrap-js.js" )
       (:script :src "/script.js" )
       (:script :src "/angular-lib.js" )
       (:script :src "/angular.js" )
       (:script :src "/angular-ui-router.js" ))
        
      (:body 
        (header)
        (:div :style "min-height:450px"
         (:h2 :style "text-align:center" ,title)
         (:br)
         ,@body)
       (footer)))))

;; header procedure
(defun header ()
  (cl-who:with-html-output (*standard-output* nil :indent t)
    (:nav :class "navbar navbar-default"
      (:div :class "container-fluid"
        (:div :class "navbar-header"
          (:button :type "button" :class "navbar-toggle collapsed" :data-toggle "collapse" :data-target "#bs-example-navbar-collapse-1" :aria-expanded "false"
            (:span :class "sr-only" "Toggle navigation")
            (:span :class "icon-bar")
            (:span :class "icon-bar")
            (:span :class "icon-bar"))
          (:a :href "/index" (:img  :class "logo" :src "/images/logo.png" )))
          ;;(:a :class "navbar-brand" :href "#" "brand"))
        (:div :class "collapse navbar-collapse" :id "bs-example-navbar-collapse-1"
          (:ul :class "nav navbar-nav navbar-right"
            (if (eq (get-user) nil)
              (before-login)
              (after-login))
            )
        )
      ))))

;; procedure to be displayed before login
(defun before-login ()
  (cl-who:with-html-output (*standard-output* nil :indent t)
    (:li :id "links" (:a :href "/user-login" "Login" (:i :class "fa fa-user fa-fw fa-2x")))
    (:li :id "links" (:a :href "/user-signup" "Signup" (:i :class "fa fa-user-plus fa-fw fa-2x")))
  ))

;; procedure to be displayed after login
(defun after-login ()
  (cl-who:with-html-output (*standard-output* nil :indent t)
    (:li (:a :class "btn btn-primary" :style "background-color:#33C7E8;color:#242727" :href "/project" "Projects"))
    (:li :class "dropdown"
    (:a :href "#" :class "dropdown-toggle" :data-toggle "dropdown" :alt "avatar"
    (:div (:img :class "user-dp" :src "/images/profile.jpg")
    (:b :class "caret")))
    (:ul :class "dropdown-menu"
      (:li (:a :href "/user-edit" "Edit account" 
            (:span :class "glyphicon glyphicon-cog pull-right")))
      (:li :role "separator" :class "divider")
      (:li (:a :href "/user-logout" "Log out" (:span :class "glyphicon glyphicon-log-out pull-right")))
    ))
  ))

;; footer content
(defun footer ()
  (cl-who:with-html-output (*standard-output* nil :indent t)
  (:footer :class "footer-distributed"
    (:div :class "footer-right"
      (:a :href "https://www.facebook.com/wolfgang.furtado10" (:i :class "fa fa-facebook"))
      (:a :href "https://twitter.com/WolfgangFurtado" (:i :class "fa fa-twitter"))
      (:a :href "https://www.linkedin.com/in/wolfgang-furtado-778063b8" (:i :class "fa fa-linkedin"))
      (:a :href "https://github.com/Wolfgang3" (:i :class "fa fa-github"))
      )
    (:div :class "footer-left"
      (:p :class "footer-links"
  (:a :href "#" "Wolfgang Furtado"))
      (:p :style "color: white;" "VacationLabs &copy; 2016")))))
