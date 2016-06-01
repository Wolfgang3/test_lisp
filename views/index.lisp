(in-package :mypackage)

(push (create-regex-dispatcher "^/index" 'index) *dispatch-table*)

(defun index ()
  (standard-page
    (:title "Welcome User")
    (:div :class "container" :style "text-align: center;"
      (:div :class "row"
        (:div :class "col-sm-2 col-md-2")
        (:div :class "col-sm-8 col-md-8"
          (:h4 "This is a release notes generator, which will help the user to generate release notes from github and asana.The user can also download the release notes.")
          (:h4 "")
          
          (:img :class "working-img" :src "/images/working.gif" :alt "working")
          (:h5 "")
          (:h5 "")))
      (:div :class "col-sm-2 col-md-2")
      )
    ))