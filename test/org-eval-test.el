;;; org-eval-test.el --- Tests for org-eval -*- lexical-binding: t; -*-

(require 'ert)
(require 'seq)
(require 'org-eval)

;;; Helper to create temporary directories and files
(defun org-eval-test--make-temp-file-in-dir (dir name)
  "Create a temporary file NAME inside directory DIR and return its path."
  (let ((file (expand-file-name name dir)))
    (with-temp-file file) ; create empty file
    file))

;;; Tests

(ert-deftest org-eval-test-safe-file-nil-prefix-list ()
  "org-eval-test-safe-file should return nil if prefix list is nil."
  (let ((org-eval-prefix-list nil))
    (should-not (org-eval-test-safe-file "/some/path/file.org"))))


(ert-deftest org-eval-test-safe-file-single-match ()
  "Should return t when PATH is inside the single allowed directory."
  (let ((org-eval-prefix-list (list temporary-file-directory))
        (file (org-eval-test--make-temp-file-in-dir temporary-file-directory "test.org")))
    (should (org-eval-test-safe-file file))))


(ert-deftest org-eval-test-safe-file-single-no-match ()
  "Should return nil when PATH is outside the allowed directory."
  (let ((org-eval-prefix-list (list "/nonexistent/dir"))
        (file (org-eval-test--make-temp-file-in-dir temporary-file-directory "test.org")))
    (should-not (org-eval-test-safe-file file))))


(ert-deftest org-eval-test-safe-file-multiple-prefixes ()
  "Should return t if PATH is inside any of multiple allowed directories."
  (let* ((dir1 (make-temp-file "org-eval-dir1" t))
         (dir2 (make-temp-file "org-eval-dir2" t))
         (org-eval-prefix-list (list dir1 dir2))
         (file1 (org-eval-test--make-temp-file-in-dir dir1 "a.org"))
         (file2 (org-eval-test--make-temp-file-in-dir dir2 "b.org"))
         (file3 (org-eval-test--make-temp-file-in-dir temporary-file-directory "c.org")))
    (should (org-eval-test-safe-file file1))
    (should (org-eval-test-safe-file file2))
    (should-not (org-eval-test-safe-file file3))))


(ert-deftest org-eval-test-safe-file-truename-symlink ()
  "Should resolve symlinks correctly."
  (let* ((real-dir (make-temp-file "org-eval-real" t))
         (link-dir (make-temp-file "org-eval-link" t))
         (file (org-eval-test--make-temp-file-in-dir real-dir "file.org")))
    ;; remove the temporary symlink dir and recreate as symlink to real-dir
    (delete-directory link-dir)
    (make-symbolic-link real-dir link-dir t)
    (let ((org-eval-prefix-list (list link-dir)))
      (should (org-eval-test-safe-file file)))))


(ert-deftest org-eval-test-safe-file-relative-paths ()
  "Should work correctly with relative paths."
  (let* ((dir (make-temp-file "org-eval-relative" t))
         (file (org-eval-test--make-temp-file-in-dir dir "file.org"))
         (rel-file (file-relative-name file default-directory))
         (org-eval-prefix-list (list dir)))
    (should (org-eval-test-safe-file rel-file))))


(ert-deftest org-eval-test-safe-file-nil-path ()
  "Should return nil if PATH is nil."
  (let ((org-eval-prefix-list (list temporary-file-directory)))
    (should-not (org-eval-test-safe-file nil))))

;;;
;; Run the test cases
;;;
(ert-run-tests-interactively t)

;;; org-people-test.el ends here
