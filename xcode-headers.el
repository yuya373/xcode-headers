;;; package --- Summary
;;; xcode-headers.el ---parse Xcode pbxproj  -*- lexical-binding: t; -*-
;;; Commentary:

;; Copyright (C) 2015  南優也

;; Author: 南優也 <yuyaminami@minamiyuunari-no-MacBook-Pro.local>
;; Keywords: convinience
;;; Code:

(provide 'xcode-headers)
(defcustom xcode-headers-pbxproj-path nil
  "Specify project.pbxproj path."
  :group 'xcode-headers
  :type 'string)
(defcustom xcode-headers-src-root nil
  "Specify $(SRCROOT) to replace."
  :group 'xcode-headers
  :type 'string)
(defcustom xcode-headers-regexp "HEADER_SEARCH_PATHS = (\\(.*?\\));"
  "Specify regexp to match."
  :group 'xcode-headers
  :type 'string)

(defun replace-src-root (string)
  (replace-regexp-in-string "$(SRCROOT)" xcode-headers-src-root string t))

(defun format-header (string)
  (split-string (replace-regexp-in-string "\"" "" string) "," t))

(defun add-if-new (headers string)
  (if (member string headers)
      headers
    (append (list string) headers)))

(defun extract-headers ()
  (let ((file-content
         (replace-regexp-in-string "\n\\|\t" ""
                                   (with-temp-buffer
                                     (insert-file-contents xcode-headers-pbxproj-path)
                                     (buffer-substring-no-properties (point-min) (point-max))))))
    (cl-labels ((do-extract (content acc start-point)
                            (if (null (string-match xcode-headers-regexp content start-point))
                                acc
                              (do-extract content
                                          (add-if-new acc
                                                      (replace-src-root
                                                       (substring content
                                                                  (car (cddr (match-data)))
                                                                  (cadr (cddr (match-data)))))
                                                      )
                                          (match-end 0)))))
      (do-extract file-content '() 0))))

(defun xcode-headers-format-for-cflags ()
  (mapcar (lambda (x)
            (concat "-I" (expand-file-name x)))
          (format-header (car (extract-headers)))))
;;; xcode-headers.el ends here
