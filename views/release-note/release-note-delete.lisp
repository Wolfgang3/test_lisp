(in-package :mypackage)

(push (create-regex-dispatcher "^/project/[0-9]+/release-note/[0-9]+/delete" 'release-note-delete) *dispatch-table*)

(defun release-note-delete ()
  (let* ((proj-id (get-project-id-from-uri))
         (release-id (get-release-id-from-uri))
         (release-dao (get-dao 'release-note release-id)))
  (delete-dao release-dao)
  (redirect (concatenate 'string "/project/" proj-id "/release-note"))
    ))