;; -*-  lexical-binding: t; -*-

;; some definitions from https://github.com/chalaev/lisp-goodies

(defmacro ifn-let(vars ifno &rest body)
  `(if-let ,vars
      (progn ,@body)
      ,ifno))

(defun pos(el ll)
  (let ((i 0) r)
  (dolist (e ll r)
    (if (eql e el)
	(setf r i)
      (cl-incf i)))))

(defvar *emacs-d* (concat "~/" (file-name-as-directory ".emacs.d")))

(defvar *log-level* 0)
(defvar *log-buffer* nil)

(let (last-FLD); saves last day printed to the log file
(defun log-flush()
  "save log messages to file for debugging"
  (when (= 0 *log-level*)
    (with-temp-buffer
      (let ((today-str (format-time-string "%04Y-%02m-%02d" (current-time))))
	(unless (string= today-str (or last-FLD ""))
	  (setf last-FLD today-str)
	  (insert today-str) (newline))
	(dolist (msg (reverse *log-buffer*))
	  (insert msg) (newline)))
      (append-to-file (point-min) (point-max) (concat *emacs-d* "elisp.log")))
    (setf *log-buffer* nil))))

(defun clog(level fstr &rest args)
  "simple logging function" ; level is one of → :debug :info :warning :error
(let ((log-push (lambda(msg)
  (push msg *log-buffer*)
  (when (< 30 (length *log-buffer*)) (log-flush)))))
(when (<= *log-level* (or (pos level '(:debug :info :warning :error)) 0))
  (let ((log-msg
	   (cons
	    (concat "%s " (format-time-string "%H:%M:%S "
(apply 'encode-time (butlast (decode-time (current-time)) 3)))
		    fstr)
	    (cons (symbol-name level) args))))
      (funcall log-push (apply #'format log-msg))
      (apply #'message log-msg)))
 nil))

(defun on-emacs-exit()
  (clog :debug "flushing comments before quiting emacs")
  (log-flush))
(add-hook 'kill-emacs-hook 'on-emacs-exit)

(defun parse-date (str)
  (mapcar 'string-to-number
	  (cond
 ((string-match "\\([0-9]\\{4\\}\\)[/-]\\([0-9][0-9]\\)[/-]\\([0-9][0-9]\\)" str) (mapcar #'(lambda (x) (match-string x str)) '(3 2 1)))
 ((string-match "\\([0-9][0-9]\\)[/-]\\([0-9][0-9]\\)[/-]\\([0-9]\\{4\\}\\)" str) (mapcar #'(lambda (x) (match-string x str)) '(2 1 3)))
 ((string-match "\\([0-9][0-9]\\)\\.\\([0-9][0-9]\\)\\.\\([0-9]\\{4\\}\\)" str) (mapcar #'(lambda (x) (match-string x str)) '(1 2 3)))
 ((string-match "\\([0-9][0-9]\\)/\\([0-9][0-9]\\)/\\([0-9]\\{2\\}\\)" str) (mapcar #'(lambda (x) (match-string x str)) '(2 1 3)))
 ((string-match "\\([0-9]\\{2\\}\\)[/-]\\([0-9][0-9]\\)" str) (append (mapcar #'(lambda (x) (match-string x str)) '(2 1)) (list (format-time-string "%Y" (current-time)))))
 (t (clog :error "date format not recognized in %s" str) nil))))


(defun str-join(lof-strings &optional separator)
  (let((sep(or separator "")))
    (seq-reduce #'(lambda(x y) (format (concat "%s" separator "%s") x y)) (cdr lof-strings) (car lof-strings))))

(defun cut-line(); replaces =delete-line= on earlier emacs versions
  (prog1
      (buffer-substring-no-properties
       (line-beginning-position) (min (point-max) (1+(line-end-position))))
    (kill-region (line-beginning-position) (min (point-max) (1+(line-end-position))))))

(defun non-empty(str)
  (and str(when(< 0 (length str)) str)))

(defun encode-date(str)
(when(and str (non-empty str) (not(string-equal "!" (substring str 0 1))))
  (when-let((pd(parse-date str)))
  (apply #'encode-time (append '(0 0 0) pd)))))

(defun format-time(format-str emcoded-time)
  (if emcoded-time
    (format-time-string format-str emcoded-time)
    ""))

(defun current-line()
  (buffer-substring-no-properties (line-beginning-position) (line-end-position)))

(defun current-table-row()
  (mapcar #'string-trim
	  (split-string
	   (string-trim (current-line)  "[| \t\n\r]"  "[| \t\n\r]")
	   "|")))

(defun goto-table(tblname)
(goto-char (point-min))
(when (re-search-forward (concat "^[ \t]*#\\+\\(tbl\\)?name:[ \t]*" (regexp-quote tblname) "[ \t]*$") nil t)
(goto-char(match-beginning 0))
(forward-line)))
