(in-package :mypackage)

(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/view" 'release-notes-view) *dispatch-table*)

;;+++++++++++++++++ view
;; the view page of the release-note
(defun release-notes-view ()
  (standard-page
    (:title "The Release Notes Content")
    (:div :class "container release-note-container" :ng-app "myapp" 
      (:div :class "release-note-details" :ui-view ""
      )
    (:h2 ""))))

