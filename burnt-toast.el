;;; burnt-toast.el --- Elisp integration with BurntToast -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2020 Sam Cedarbaum
;;
;; Author: Sam Cedarbaum (scedarbaum@gmail.com)
;; Keywords: alert notifications powershell
;; Homepage: https://github.com/cedarbaum/burnt-toast.el
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))
;; License: GPL3

;;; Commentary:

;; Elisp integration with BurntToast, a PowerShell module for displaying Windows 10 and Windows Server 2019 Toast Notifications.

;;; Code:

(require 'dash)

(defcustom burnt-toast-powershell-command "powershell"
  "Command to invoke PowerShell."
  :type 'string
  :group 'burnt-toast)

(defvar burnt-toast--verbose nil)

;; Based on: https://github.com/mplscorwin/erc-burnt-toast/blob/master/erc-burnt-toast.el
(defun burnt-toast--clean-powershell-input (string)
  "Return a version of STRING sanitized for use as input to PowerShell.
New-lines are removed, trailing spaces are removed, and single-quotes are doubled."
  (when (stringp string)
    (org-no-properties
     (replace-regexp-in-string
      "\s+$" ""
        (replace-regexp-in-string
         "[\t\n\r]+" ""
         (replace-regexp-in-string
          "\"" "\"\""
          string))))))

(defun burnt-toast--quote-and-sanitize-string (string)
  "Surround STRING with double quotes when it is non-nil."
  (when string
    (concat "\"" (burnt-toast--clean-powershell-input string) "\"")))

(defun burnt-toast--nil-string-to-empty (string)
  "Return STRING when a non-nil string or an empty string otherwise."
  (if (stringp string)
      string
    ""))

(defun burnt-toast--run-powershell-command (command-and-args)
  "Execute a PowerShell command COMMAND-AND-ARGS."
  (let* ((ps-base-command (list burnt-toast-powershell-command nil nil nil))
         (all-args (add-to-list 'ps-base-command command-and-args t)))
    (when burnt-toast--verbose (message command-and-args))
    (apply 'call-process all-args)))

(defun burnt-toast--new-ps-object (object args)
  "Create a new PowerShell OBJECT using ARGS."
  (let* ((prefix-string (concat "$(New-" object " "))
         (non-nil-args (-filter (-lambda ((_ value)) value) args))
         (args-string-list (-map
                            (-lambda ((arg value)) (concat "-" arg " " (burnt-toast--nil-string-to-empty value)))
                            non-nil-args))
         (args-string (-reduce (lambda (s1 s2) (concat s1 " " s2)) args-string-list)))
    (concat prefix-string args-string ")")))


(cl-defun burnt-toast--new-notification-core (&key text app-logo sound header silent snooze-and-dismiss)
  "Create new notification with subset of arguments.
This function should not be called directly."
  (let* ((processed-text (if (and text (listp text))
                             (-reduce
                              (lambda (s1 s2) (concat s1 "," s2))
                              (-map 'burnt-toast--quote-and-sanitize-string text))
                           (burnt-toast--quote-and-sanitize-string text)))
         (ps-command (burnt-toast--new-ps-object
                      "BurntToastNotification"
                      `(("Text"             ,processed-text)
                        ("AppLogo"          ,app-logo)
                        ("Sound"            ,sound)
                        ("Header"           ,header)
                        ("Silent"           ,silent)
                        ("SnoozeAndDismiss" ,snooze-and-dismiss)))))
    (burnt-toast--run-powershell-command ps-command)))

;;;###autoload
(defun burnt-toast/bt-header-object (id title)
  "Create a new BTHeader with ID and TITLE."
  (burnt-toast--new-ps-object
   "BTHeader"
   `(("Id"    ,id)
     ("Title" ,(burnt-toast--quote-and-sanitize-string title)))))

;;;###autoload
(cl-defun burnt-toast/new-notification-with-sound (&key text app-logo sound header)
  "Create new notification with TEXT, APP-LOGO, SOUND, and HEADER."
  (burnt-toast--new-notification-core
   :text text
   :app-logo app-logo
   :sound sound
   :header header))

;;;###autoload
(cl-defun burnt-toast/new-notification-silent (&key text app-logo header)
  "Create new notification with TEXT, APP-LOGO, and HEADER."
  (burnt-toast--new-notification-core
   :text text
   :app-logo app-logo
   :silent t
   :header header))

;;;###autoload
(cl-defun burnt-toast/new-notification-snooze-and-dismiss-with-sound (&key text app-logo header sound)
  "Create new snooze-and-dismiss notification with TEXT, APP-LOGO, HEADER, and SOUND."
  (burnt-toast--new-notification-core
   :text text
   :app-logo app-logo
   :sound sound
   :snooze-and-dismiss t
   :header header))

;;;###autoload
(cl-defun burnt-toast/new-notification-snooze-and-dismiss-silent (&key text app-logo header)
  "Create new snooze-and-dismiss notification with TEXT, APP-LOGO, and HEADER."
  (burnt-toast--new-notification-core
   :text text
   :app-logo app-logo
   :silent t
   :snooze-and-dismiss t
   :header header))

;;;###autoload
(cl-defun burnt-toast/new-shoulder-tap (image person &key text app-logo header)
  "Create new shoulder tap with IMAGE, PERSON, TEXT, APP-LOGO, and HEADER."
  (let* ((processed-text (if (and text (listp text))
                             (-reduce
                              (lambda (s1 s2) (concat s1 "," s2))
                              (-map 'burnt-toast--quote-and-sanitize-string text))
                           (burnt-toast--quote-and-sanitize-string text)))
         (ps-command (burnt-toast--new-ps-object
                      "BurntToastShoulderTap"
                      `(("Image"   ,image)
                        ("Person"  ,person)
                        ("Text"    ,processed-text)
                        ("AppLogo" ,app-logo)
                        ("Header"  ,header)))))
    (burnt-toast--run-powershell-command ps-command)))

(provide 'burnt-toast)
;;; burnt-toast.el ends here
