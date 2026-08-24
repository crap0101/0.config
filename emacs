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
(defvar gnu+linux (string-equal system-type "gnu/linux"))
(defvar syswin (string-equal system-type "windows-nt"))

;; more debugging
(toggle-debug-on-error)

;; maximize window
(setq initial-frame-alist '((fullscreen . maximized)))

;; set & start emacs server
(require 'server)
;;(setq server-name "emacs-server-main")
(unless (server-running-p)
  (server-start)
  (message (format "server started (%s)" (server-running-p))))

;;;;;;;;;;;;;;;;;;;
;; load packages ;;
;;;;;;;;;;;;;;;;;;;

;; vibuf: load
(when gnu+linux
  (add-to-list 'load-path "/home/crap0101/local/share/emacs"))
(when syswin
  (add-to-list 'load-path "c:/Users/c24p0/AppData/Roaming/.emacs.d/lisp"))
(require 'vibuf)
;; vibuf: add hooks
(add-hook 'find-file-hook 'vibuf-create-buffer-hook-function)
(add-hook 'kill-buffer-hook 'vibuf-kill-buffer-hook-function)
(add-hook 'emacs-startup-hook 'vibuf-set__buffer-list-default)
(add-hook 'emacs-startup-hook (lambda () (vibuf-set__excluded-names vibuf__excluded-names)))
;; vibuf: set some vars
(vibuf-set__buffer-name-if-empty "*scratch*")
;; vibuf: set key bindings
(global-set-key (kbd "C-S-<left>") (lambda () (interactive) (vibuf-prev-buffer)))
(global-set-key (kbd "C-S-<right>") (lambda () (interactive) (vibuf-next-buffer)))


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
            (setq-local mouse-1-click-follows-link nil)
            ;(define-key dired-mode-map [C-up] ') ;XXX+TODO: go to the last visited dir
            (define-key dired-mode-map [C-down] 'dired-up-directory)
            (define-key dired-mode-map [mouse-1] 'dired-mouse-find-file-other-window)
            (define-key dired-mode-map [mouse-2] 'dired-replace-buffer__mouse-event)))


;; backtrace view
(add-hook 'backtrace-mode-hook 'visual-line-mode)

;;;;;;;;;;;;;;;;;;;;;;
;; custom functions ;;
;;;;;;;;;;;;;;;;;;;;;;

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
(defun search-region (start end)
  "Starts a search using the region of the current buffer."
  (interactive "r")
  (setq search-region__previous_cs case-fold-search)
  (setq case-fold-search nil)
  (isearch-mode t nil nil nil)
  (deactivate-mark)
  (isearch-yank-string (buffer-substring-no-properties start end))
  (setq case-fold-search search-region__previous_cs))

;; search by region, case-insensitive
(defun isearch-region (start end)
  "Starts a search using the region of the current buffer."
  (interactive "r")
  (setq search-region__previous_cs case-fold-search)
  (setq case-fold-search t)
  (isearch-mode t nil nil nil)
  (deactivate-mark)
  (isearch-yank-string (buffer-substring-no-properties start end))
  (setq case-fold-search search-region__previous_cs))

;; uppercase region
(defun uppercase-region (start end)
  "uppercase the region of the current buffer."
  (interactive "r")  
  (deactivate-mark)
  (upcase-region start end))

;; downcase region
(defun lowercase-region (start end)
  "lowercase the region of the current buffer."
  (interactive "r")  
  (deactivate-mark)
  (downcase-region start end))

;; capitalize region
(defun cap-region (start end)
  "capitalize the region of the current buffer."
  (interactive "r")  
  (deactivate-mark)
  (capitalize-region start end))

;; open file from region
(defun open-file-from-region (start end)
  "open the filename from the region of the current buffer"
  (interactive "r")
  (deactivate-mark)
  (switch-to-buffer
    (find-file-noselect
      (buffer-substring-no-properties start end)  nil nil nil)))

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


;;;;;;;;;;;;;;
;; bindings ;;
;;;;;;;;;;;;;;

;; redefine this: change focus forward
(global-set-key (kbd "C-c w") 'other-window)
;; change focus backward
(global-set-key (kbd "C-c q") (lambda () (interactive) (other-window -1)))

;; change font size with C-[MouseWheelUpOrDown]
(global-set-key (kbd "<C-mouse-4>") (lambda () (interactive) (text-scale-decrease 1)))
(global-set-key (kbd "<C-mouse-5>") (lambda () (interactive) (text-scale-increase 1)))

;; revert buffer
(global-set-key [f1] (lambda () (interactive)
		       (progn (revert-buffer nil t t) (message "%s" "buffer reverted"))))

;; for previously defined functions:
(global-set-key "\C-cg" 'go-line)
(global-set-key "\C-c\C-c" 'copy-lines)
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
            (define-key python-mode-map [f2] 'run-python-program)
            (define-key python-mode-map [f3] 'run-pythonXY-program)
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
(setq-default browse-url-browser-function 'browse-url-firefox
	      browse-url-firefox-program "firefox-esr")

;; no beep
(setq-default visible-bell t)

;; text related
(setq-default indent-tabs-mode nil
	      tab-width 4
	      term-input-autoexpand t
	      x-select-enable-clipboard t)
; for C-q
(setq-default fill-column 85)
(setq-default sentence-end-double-space nil)

;; columns and rows
(line-number-mode t)
(column-number-mode t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set color, faces and similar stuffs ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
(set-frame-font "DejaVu Sans Mono 15")

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

