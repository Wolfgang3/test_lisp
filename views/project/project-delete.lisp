(in-package :mypackage)

(push (create-regex-dispatcher "^/project/[0-9]+/delete" 'project-delete) *dispatch-table*)

(defun project-delete ()
  (let* ((proj-id (get-project-id-from-uri))
         (proj-dao (get-dao 'project proj-id)))
  (delete-dao proj-dao)
  (redirect "/project")
    ))