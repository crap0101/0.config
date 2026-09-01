;; .emacs init file

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;; author: Marco Chieppa | crap0101 ...with some help from Custom :D


;;;;;;;;;;;;;;;;;
;; init stuffs ;;
;;;;;;;;;;;;;;;;;

;; system type
(defvar is_gnu+linux (eq system-type 'gnu/linux))
(defvar is_syswin (eq system-type 'windows-nt))
(defvar is_android (eq system-type 'android))


;; more debugging
(toggle-debug-on-error)


;; backtrace view
(add-hook 'backtrace-mode-hook 'visual-line-mode)


;; maximize window (not on android)
(unless is_android
  (setq initial-frame-alist '((fullscreen . maximized))))


;; set & start emacs server
(require 'server)
;;(setq server-name "emacs-server-main")
(unless (server-running-p)
  (when is_android
    (setq server-use-tcp t
          server-host "127.0.0.1"
          server-port 60325))
    (server-start)
    (message (format "server started (%s)" (server-running-p))))


;; set path to shared folder on (FUCKING) android
(when is_android
  (defun shared-folder ()
    (interactive)
    (dired "/content/storage/com.android.externalstorage.documents/primary:Documents/emacs/"))
  (global-set-key (kbd "<f5>") 'shared-folder))


;;;;;;;;;;;;;;;;;;;;;;
;; packages / modes ;;
;;;;;;;;;;;;;;;;;;;;;;


;; vibuf: load (not on android)
(unless is_android
  (when is_gnu+linux
    (add-to-list 'load-path "/home/crap0101/local/share/emacs"))
  (when is_syswin
    (add-to-list 'load-path (file-name-concat (expand-file-name "~") ".emacs.d/lisp")))
  (require 'vibuf)
  ;; vibuf: hooks
  (add-hook 'find-file-hook 'vibuf-create-buffer-hook-function)
  (add-hook 'kill-buffer-hook 'vibuf-kill-buffer-hook-function)
  (add-hook 'emacs-startup-hook 'vibuf-set__buffer-list-default)
  (add-hook 'emacs-startup-hook (lambda () (vibuf-set__excluded-names vibuf__excluded-names)))
  ;; vibuf: set some vars
  (vibuf-set__buffer-name-if-empty "*scratch*")
  ;; vibuf: key bindings
  (global-set-key (kbd "C-S-<left>") (lambda () (interactive) (vibuf-prev-buffer)))
  (global-set-key (kbd "C-S-<right>") (lambda () (interactive) (vibuf-next-buffer))))


;; recentf
(require 'recentf)
(recentf-mode 1)
(add-hook 'buffer-list-update-hook 'recentf-track-opened-file)


;; org-mode
(add-hook 'org-mode-hook
          (lambda ()
            (setq fill-column 80)
            (display-fill-column-indicator-mode 1)
            (refill-mode 1)
            (org-indent-mode 1)
            (setq org-latex-compiler "latexmk")
            (setq org-latex-pdf-process
                  '("%latex -pdfxe -output-directory=%o"))))


;; dired
(require 'ring)
(defcustom dired__last-visited-len 25 "length for the custom dired ring")
(defvar dired__last-visited (make-ring dired__last-visited-len))
(defvar dired__track-this t)

(defun dired__last-visited ()
  "Go to the last visited directory, excluding ones visited from this function."
  (interactive)
  (if (ring-empty-p dired__last-visited)
      (message "dired__last-visited is empty!")
    (let ((last-visited (ring-ref dired__last-visited 0)))
      (if (derived-mode-p 'dired-mode)  ;; in case want to call this function interactively
          (progn
            (ring-insert-at-beginning dired__last-visited (ring-remove dired__last-visited 0))
            (setq dired__track-this nil)
            (find-alternate-file (ring-ref dired__last-visited 0)))
        (progn
          (setq dired__track-this nil)
          (dired last-visited))))))

(defun dired-replace-buffer__mouse-event (event)
    "Replace the current dired buffer with the clicked file/dir"
    (interactive "e")
    (mouse-set-point event)
    (let ((selected-file (dired-get-filename nil t))
          (original-buffer (current-buffer)))
      (when selected-file
        (if (file-directory-p selected-file)
            (dired-find-alternate-file)
          (switch-to-buffer (find-file-noselect selected-file))))))

(add-hook 'dired-mode-hook
          (lambda ()
            (put 'dired-find-alternate-file 'disabled nil)
            (setq-local mouse-1-click-follows-link nil)))

(add-hook 'dired-mode-hook
          (lambda ()
            (if dired__track-this
                (ring-insert dired__last-visited dired-directory))
            (setq dired__track-this t)))

(with-eval-after-load 'dired
  (define-key dired-mode-map "r" 'dired__last-visited)
  (define-key dired-mode-map "z" 'dired-up-directory)
  (define-key dired-mode-map [mouse-1] 'dired-mouse-find-file-other-window)
  (define-key dired-mode-map [mouse-2] 'dired-replace-buffer__mouse-event))


;; lisp mode
(define-key lisp-mode-shared-map (kbd "C-c C-SPC") 'comment-or-uncomment-region)

(dolist (hook '(emacs-lisp-mode-hook lisp-interaction-mode-hook))
  (add-hook hook
            (lambda ()
              (local-set-key (kbd "C-c e") 'eval-region))))


;;;;;;;;;;;;;;;;;;;;;;
;; custom functions ;;
;;;;;;;;;;;;;;;;;;;;;;

;; lists local variables
(defun local-variables-in-buffer (&optional buff showvalue separator value-separator)
  "Lists the local variables of buffer *buff* (or, if nil, the current buffer)
in a new text buffer. If *showvalue* is not nil, show also their value.
*separator* is used when *showvalue* is nil (default to newline)
*value-separator when *showvalue* is not nil (default to \"\\n=====================================\\n\")
Example:
  (local-variables-in-buffer)  ;; list only the variables of the current buffer
  (local-variables-in-buffer nil 1 nil nil)  ;; list the variables and the values of the current buffer
  (local-variables-in-buffer nil 1 nil \"\\n***\\n\")  ;; alternative separator: newlines to be used to have the other separator characters alone on one line.
  (local-variables-in-buffer (next-buffer) 1 nil nil)  ;; lists the variables from the buffer returned by next-buffer."
  (let* ((target-buffer (or buff (current-buffer)))
         (local-list (seq-filter (lambda (x) (local-variable-p (car x))) (buffer-local-variables target-buffer)))
         (bufname (buffer-name target-buffer))
         (sep (or separator "\n"))
         (kvsep (or value-separator "\n=====================================\n")))
    (switch-to-buffer (generate-new-buffer-name (format "local-vars_%s" bufname)))
    (if showvalue
        (setq-local str-vars (mapconcat (lambda (x) (format "%s: %s" (car x) (format "%s" (cdr x)))) local-list kvsep))
      (setq-local str-vars (mapconcat (lambda (x) (format "%s" (car x))) local-list sep)))
    (insert str-vars)))

;; custom switch-to-buffer
(defun go-buffer (buffer-name)
  "Switch to the buffer which name is the most similar
(Levenshtein distance, after regex's filtering) to *buffer-name*,
searching in the current buffer-list."
  (interactive "MBuffer name: ")
  (let ((min-distance 1000)
        (match-found nil)
        (buffer-names
         (seq-filter (lambda (b) (not (string-prefix-p " " b)))
                     (mapcar #'buffer-name (buffer-list)))))
    (dolist (name buffer-names)
      (when (string-match buffer-name name)
        (let ((distance (string-distance name buffer-name)))
          (when (< distance min-distance)
            (setq min-distance distance)
            (setq match-found name)))))
    (if match-found
        (switch-to-buffer match-found)
      (message "No buffer similar to: %s" buffer-name))))

;; custom goto-line
(defun go-line (num)
  "go to the *num*th line of the current buffer.
NOTE: If *num* is lesser than 1 or negative, counts from the
end of the buffer; else if greater than the number of
buffer's lines, go to the last line."
  (interactive "NGo to line: ")
  (push-mark)
  (let ((actual-line (line-number-at-pos)))
    (let ((lines (line-number-at-pos (point-max))))
      (if (> num lines)
          (forward-line (- lines actual-line))
        (if (<= num 0)
            (forward-line (+ (- lines actual-line) num))
          (forward-line (- num actual-line)))))))

;; copy-line shortcut
(defun copy-lines (&optional arg)
  "Copy *arg* lines in the kill ring (default: the current line)."
  (interactive "p")
  (kill-ring-save (line-beginning-position)
		  (line-beginning-position (+ 1 (if arg arg 1)))))

(defun uppercase-word (&optional n)
  "upcase the ENTIRE *n* words (default 1) from the point."
  (interactive "P")
  (let ((c (char-after (point))))
    (if (and (not (null c)) (eq ?w (char-syntax c)))
	(let ((p (char-after (- (point) 1))))
	  (if (or (not (null p)) (eq ?w (char-syntax (char-after p))))
	      (backward-to-word)))
      (forward-to-word))
    (upcase-word (if n n 1))))

(defun lowercase-word (&optional n)
  "lowcase the ENTIRE *n* words (default 1) from the point."
  (interactive "P")
  (let ((c (char-after (point))))
    (if (and (not (null c)) (eq ?w (char-syntax c)))
	(let ((p (char-after (- (point) 1))))
	  (if (or (not (null p)) (eq ?w (char-syntax (char-after p))))
	      (backward-to-word)))
      (forward-to-word))
    (downcase-word (if n n 1))))

;; search by region, case-sensitive
(defun search-region ()
  "Starts a search using the region of the current buffer."
  (interactive)
  (if (use-region-p)
      (progn
        (setq search-region__previous_cs case-fold-search)
        (setq case-fold-search nil)
        (isearch-mode t nil nil nil)
        (deactivate-mark)
        (isearch-yank-string
         (buffer-substring-no-properties (region-beginning) (region-end)))
        (setq case-fold-search search-region__previous_cs))
    (message "search-region: no active region!")))

;; search by region, case-insensitive
(defun isearch-region ()
  "Starts a search using the region of the current buffer."
  (interactive)
  (if (use-region-p)
      (progn
        (setq search-region__previous_cs case-fold-search)
        (setq case-fold-search t)
        (isearch-mode t nil nil nil)
        (deactivate-mark)
        (isearch-yank-string
         (buffer-substring-no-properties (region-beginning) (region-end)))
        (setq case-fold-search search-region__previous_cs))
    (message "isearch-region: no active region!")))

;; uppercase region
(defun uppercase-region ()
  "uppercase the region of the current buffer."
  (interactive)
  (if (use-region-p)
      (progn
        (upcase-region (region-beginning) (region-end))
        (deactivate-mark))
    (message "uppercase-region: no active region!")))

;; downcase region
(defun lowercase-region ()
  "lowercase the region of the current buffer."
  (interactive)
  (if (use-region-p)
      (progn
        (message "there is a region")
        (downcase-region (region-beginning) (region-end))
        (deactivate-mark))
    (message "lowercase-region: no active region!")))

;; capitalize region
(defun cap-region ()
  "capitalize the region of the current buffer."
  (interactive)
  (if (use-region-p)
      (progn
        (message "there is a region")
        (capitalize-region (region-beginning) (region-end))
        (deactivate-mark))
    (message "cap-region: no active region!")))

;; open file from region
(defun open-file-from-region ()
  "Open the filename from the region of the current buffer"
  (interactive)
  (if (use-region-p)
      (progn
        (deactivate-mark)
        (let ((start (region-beginning))
              (end (region-end)))
          (switch-to-buffer
           (find-file-noselect
            (buffer-substring-no-properties start end)  nil nil nil))))
    (message "open-file-from-region: no active region!")))

;; open url from region
(defun open-url-from-region (&optional fallback)
  "Open the url from the region of the current buffer.
When no region is selected and *fallback* is not nil,
tries to get the url from the current point and open it."
  (interactive)
  (if (use-region-p)
      (progn
        (message "region selected")
        (let ((start (region-beginning))
              (end (region-end)))
          (deactivate-mark)
          (browse-url (buffer-substring-no-properties start end))))
    (save-excursion
      (when fallback
        (let
            ((start (progn (forward-thing 'whitespace -1) (forward-to-word) (point)))
             (end (progn (forward-thing 'whitespace 1) (backward-to-word) (point))))
          (browse-url (buffer-substring-no-properties start end)))))))

;; insert date
(defun insert-date (prefix)
    "Insert the current date in the YYYY-MM-DD format."
    (interactive "P")
    (insert (format-time-string "%Y-%m-%d")))

;; run python program
(defun run-python-program (&optional python-name)
  "Run the python programs in the current buffer"
  (interactive)
  (let ((pyv (if python-name python-name "python")))
    (if (string= (save-excursion (current-buffer) major-mode) "python-mode")
	(progn (message
		(concat "Running " pyv  " script "
			(car (reverse (split-string (buffer-name) "/")))))
	       (shell-command
		(concat "/usr/bin/env " pyv " " (buffer-file-name))))
      (message (concat
		"Error: This not seem a python file. Nothing executed. ("
		(symbol-name
		 (save-excursion (current-buffer) major-mode)) ")")))))

;; run python program (choose executable)
(defun run-pythonXY-program (python-name)
  (interactive "sPython name: ")
  (run-python-program python-name))

;; number to subscript (O2 -> O₂)
(defun number-to-subscript ()
  (let* ((cursor-info (what-cursor-position))
	 (ival (progn (string-match "(\\([0-9]+\\)" cursor-info)
		      (string-to-number (match-string 1 cursor-info)))))
    (if (and (>= ival 48) (<= ival 57))
	(progn
	  (delete-char 1)
	  (insert (format "%c" (+ 8272 ival)))))))


;;;;;;;;;;;;;;;;;;
;; key bindings ;;
;;;;;;;;;;;;;;;;;;

;; NOTE: see above for *set-key on android, vibuf and lisp-mode

;; redefine this: change focus forward
(global-set-key (kbd "C-c w") 'other-window)
;; change focus backward
(global-set-key (kbd "C-c q") (lambda () (interactive) (other-window -1)))

;; change font size with C-[MouseWheelUpOrDown]
(global-set-key (kbd "<C-mouse-4>") (lambda () (interactive) (text-scale-decrease 1)))
(global-set-key (kbd "<C-mouse-5>") (lambda () (interactive) (text-scale-increase 1)))

;; revert buffer
(global-set-key (kbd "<f1>") (lambda () (interactive)
		       (progn (revert-buffer nil t t) (message "%s" "buffer reverted"))))

;; open urls
(global-set-key (kbd "C-c C-u") (lambda () (interactive) (open-url-from-region 1)))

;; for previously defined functions:
(global-set-key (kbd "C-c b") 'go-buffer)
(global-set-key (kbd "C-c g") 'go-line)
(global-set-key (kbd "C-c C-c") 'copy-lines)
; C-c C-c for copy the current line
; C-u N C-c C-c to copy N lines
(global-set-key (kbd "C-S-s") 'isearch-region)
(global-set-key (kbd "C-c C-S") 'search-region)
(global-set-key (kbd "C-c C-f") 'open-file-from-region)
(global-set-key (kbd "C-c d") 'insert-date)
(global-set-key (kbd "C-c u") 'uppercase-region)
(global-set-key (kbd "C-c l") 'lowercase-region)
(global-set-key (kbd "C-c c") 'cap-region)
(global-set-key (kbd "M-u") 'uppercase-word)
(global-set-key (kbd "M-l") 'lowercase-word)
(global-set-key (kbd "M-s") (lambda () (interactive) (number-to-subscript)))
(with-eval-after-load 'python
            (define-key python-mode-map (kbd "<f2>") 'run-python-program)
            (define-key python-mode-map (kbd "<f3>") 'run-pythonXY-program)
            (define-key python-mode-map (kbd "C-c C-SPC") 'comment-or-uncomment-region))


;;;;;;;;;;;;;;;;;;;;;;;;
;; set some variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; http://lists.gnu.org/archive/html/emacs-devel/2011-09/msg00350.html
(setq-default redisplay-dont-pause t)

;; https://lists.gnu.org/archive/html/bug-gnu-emacs/2010-11/msg00243.html
(setq-default focus-follows-mouse nil)

;; keep the cursor at the same screen position whenever a scroll command moves it off-window
(setq-default scroll-preserve-screen-position t)

;; browser
(when is_android
  (setq browse-url-browser-function 'browse-url-default-android-browser))
(unless is_android
  (setq-default browse-url-browser-function 'browse-url-firefox
	      browse-url-firefox-program "firefox-esr"))
; should be nil by default:
(setq-default browse-url-new-window-flag nil)

;; no beep
(setq-default visible-bell t)

;; text related
(setq-default indent-tabs-mode nil
	          tab-width 4
	          term-input-autoexpand t
	          select-enable-clipboard t)
; for C-q
(setq-default fill-column 85)
(setq-default sentence-end-double-space nil)

;; columns and rows
(line-number-mode t)
(column-number-mode t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set color, faces and similar stuffs ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(unless is_android
  ;; (set-background-color "#000000") ;"#333333")
  ;; (set-foreground-color "#33CC00")
  (set-face-attribute 'default t
                      :stipple nil
                      :inverse-video nil
                      :box nil
                      :strike-through nil
                      :overline nil
                      :underline nil
                      :slant 'normal
                      :weight 'normal
                      :height 140
                      :width 'normal
                      :family "DejaVu Sans Mono")
  (set-face-attribute 'region nil :background "#666666")
  (set-frame-font "DejaVu Sans Mono 15"))


;; diff colors
(defun update-diff-colors ()
  "update the colors for diff faces"
  (set-face-attribute 'diff-added nil
                      :background "green")
  (set-face-attribute 'diff-removed nil
                      :background "red")
  (set-face-attribute 'diff-changed nil
                      :background "blue"))
(eval-after-load "diff-mode" '(update-diff-colors))

;; rust ;;
;;(add-to-list 'load-path "/home/crap0101/.emacs.d/rust")
;;(require 'rust-mode)

