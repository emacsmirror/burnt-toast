;;; burnt-toast-alert.el --- BurntToast integration with alert package -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2020 Sam Cedarbaum

;; Author: Sam Cedarbaum (scedarbaum@gmail.com)

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; BurntToast integration with alert package.

;;; Code:

(require 'burnt-toast)
(require 'alert)

(defcustom burnt-toast-icon-path (concat (file-name-directory load-file-name) "icons/emacs.png")
  "Path to icon to use for notifications."
  :type 'string
  :group 'burnt-toast)

(defcustom burnt-toast-alert-enable-remover nil
  "Non-nil if alert should remove notifications, nil otherwise."
  :type 'boolean
  :group 'burnt-toast)

(alert-define-style 'burnt-toast :title "Burnt Toast"
                    :notifier
                    (lambda (info)
                      (let*
                          ;; The message text is :message
                          ((message (plist-get info :message))
                           ;; The :title of the alert
                           (title (plist-get info :title))
                           ;; The :category of the alert
                           ;; (category (plist-get info :category))
                           ;; The major-mode this alert relates to
                           ;; (mode (plist-get info :mode))
                           ;; The buffer the alert relates to
                           ;; (buffer (plist-get info :buffer))
                           ;; Severity of the alert.  It is one of:
                           ;;   `urgent'
                           ;;   `high'
                           ;;   `moderate'
                           ;;   `normal'
                           ;;   `low'
                           ;;   `trivial'
                           ;; (severity (plist-get info :severity))
                           ;; Data which was passed to `alert'.  Can be
                           ;; anything.
                           ;; (data (plist-get info :data))
                           ;; Whether this alert should persist, or fade away
                           (id (plist-get info :id))
                           (persistent (plist-get info :persistent)))
                        (if persistent
                            (burnt-toast-new-notification-snooze-and-dismiss-with-sound
                             :app-logo burnt-toast-icon-path
                             :text `(,title ,message)
                             :unique-identifier id)
                          (burnt-toast-new-notification-with-sound
                           :app-logo burnt-toast-icon-path
                           :text `(,title ,message)
                           :unique-identifier id))))
                    :remover
                    (lambda (info)
                      (when-let ((id (plist-get info :id)))
                        (and burnt-toast-alert-enable-remover (burnt-toast-remove-notification :group id)))))

(provide 'burnt-toast-alert)
;;; burnt-toast-alert.el ends here
