;;; ============================================================================
;;; PERFORMANCE OPTIMIZATIONS - Keep at top of file
;;; ============================================================================

;; Increase garbage collection threshold during startup (reset later)
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Restore after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)  ; 16MB
                  gc-cons-percentage 0.1)))

;; Reduce file-name-handler-alist during startup
(defvar file-name-handler-alist-original file-name-handler-alist)
(setq file-name-handler-alist nil)
;; Restore before command-line file args are opened; TRAMP depends on this.
(add-hook 'after-init-hook
          (lambda ()
            (setq file-name-handler-alist file-name-handler-alist-original)))

;; Don't load outdated bytecode
(setq load-prefer-newer t)

;; Mint uses GitFS/sparse checkout. Emacs VC probes can expand the sparse index
;; and make opening files take 10+ seconds. Remote VC probes are also slow.
(require 'vc)
(setq vc-ignore-dir-regexp
      (concat vc-ignore-dir-regexp
              "\\|"
              tramp-file-name-regexp
              "\\|"
              (regexp-quote (expand-file-name "~/stripe/mint/"))))

;; Report startup time
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs loaded in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))

;;; ============================================================================
;;; UI Configuration
;;; ============================================================================

;; Turn off mouse interface early in startup to avoid momentary display
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; No splash screen or startup message
(setq inhibit-startup-screen t)
(put 'inhibit-startup-echo-area-message 'saved-value
     (setq inhibit-startup-echo-area-message (user-login-name)))
(setq ring-bell-function 'ignore)
(defun display-startup-echo-area-message ()
  (message ""))

(global-display-line-numbers-mode)
(column-number-mode)

(defvar use-package-verbose t)

(when (string= system-type "darwin")
  (setq dired-use-ls-dired nil))


;; Ensure we split to L|R windows, instead of top/bottom
(defun split-window-prefer-horizonally (window)
  "If there's only one window (excluding any possibly active
         minibuffer), then split the current window horizontally."
  (if (and (one-window-p t)
           (not (active-minibuffer-window)))
      (let ((split-height-threshold nil))
        (split-window-sensibly window))
    (split-window-sensibly window)))

(setq split-window-preferred-function 'split-window-prefer-horizonally)
(setq register-preview-delay 0)

;; case insensitive tab completion
(setq completion-ignore-case t)

(setq org-confirm-babel-evaluate nil)

;; TODO: creating tags
;; for python, this suffices:
;;  find . -name "*.[py]" -print | etags -

;; Visually highlights the active line.
;; (global-hl-line-mode)


(defalias 'yes-or-no-p 'y-or-n-p)
;; (fset 'yes-or-no-p 'y-or-n-p)  -- TODO: how does the above line differ?
(setq kill-buffer-query-functions
      (delq 'process-kill-buffer-query-function kill-buffer-query-functions))


;; Write backup files to own directory
(setq backup-directory-alist
      `(("." . ,(expand-file-name
                 (concat user-emacs-directory "backups")))))

;; TODO: do we still want the below files?
;; (setq auto-save-default nil)
;; (setq auto-save-list-file-prefix nil)
;; (setq create-lockfiles nil)
;; Make backups of files, even when they're in version control
(setq vc-make-backup-files t)


(require 'ansi-color)
(defun display-ansi-colors ()
  (interactive)
  (ansi-color-apply-on-region (point-min) (point-max)))

;; (setq uniquify-buffer-name-style 'forward)
;; TODO: can likely do this without (require 'uniquify)
(require 'uniquify)
(setq
 uniquify-buffer-name-style 'post-forward
 uniquify-separator ":")

(setq-default indent-tabs-mode nil)
;; PERFORMANCE: Delete trailing whitespace only in prog-mode (not all files)
;; If you want it for all files, uncomment the line below:
;; (add-hook 'before-save-hook 'delete-trailing-whitespace)
(add-hook 'prog-mode-hook
          (lambda ()
            (add-hook 'before-save-hook 'delete-trailing-whitespace nil 'local)))
;; auto revert all buffers (files + directories)
(setq global-auto-revert-non-file-buffers t)
(global-auto-revert-mode 1)
(setq auto-revert-remote-files t) ;; and also over tramp for remote files.

;; replace highlighted text typed text
(delete-selection-mode t)

;; move through mixed-case words by subwords
(add-hook 'web-mode-hook 'subword-mode)

;; No backslashes on long lines.
(set-display-table-slot standard-display-table 'wrap ?\ )

;; Auto refresh buffers
(global-auto-revert-mode 1)
;; Also auto refresh dired, but be quiet about it
(setq global-auto-revert-non-file-buffers t)
(setq auto-revert-verbose nil)


;;; WHEN PAIRING

;; (global-hl-line-mode 1)

;;; C-x $ == selective display == fold things
;;; ;; M-x view-mode (  == M-x M-q == read only)
;;;; If it is really big, might want to do selective display
;;;; after first makeing an indirect buffer (M-x make-indirect-buffer)



;; Scroll one line at a time
(setf scroll-conservatively 10000)

;; Stop the horrible scrolling: smooth scroll for a shell
(remove-hook 'comint-output-filter-functions
             'comint-postoutput-scroll-to-bottom)



;; https://www.emacswiki.org/emacs/RecentFiles
(recentf-mode 1)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25)
(global-set-key "\C-x\ \C-r" 'recentf-open-files)


(setq initial-scratch-message nil)
(setenv "PAGER" "/bin/cat")


(defun highlight-all-buffers (phrase)
  (interactive "sstring to be matched: ")
  ;; TODO: allow color selection
  (mapcar (lambda (buf)
            (with-current-buffer buf

              (highlight-regexp phrase 'hi-blue)
              )
            )
          (buffer-list)
          )
  )



(defun new-shell (shell-name)
  "Make sure this shell exists and is running a shell process"
  "TODOS: "
  "handle the case where this buffer name exists"
  "don't open new window with this buffer"
  (if (not (member shell-name (mapcar (lambda (buffer) (buffer-name buffer))
                                      (buffer-list))))
      (let ((source-local-profile (and (eq system-type 'darwin)
                                       (not (file-remote-p default-directory)))))
        (with-current-buffer (shell shell-name)
          (when source-local-profile
            (process-send-string shell-name ". ~/.bash_profile\n"))
          (process-send-string shell-name "[ \"$TERM\" = \"dumb\" ] && export PAGER=/bin/cat\n")
          (process-send-string shell-name "PS1='$ '\n")))
    (switch-to-buffer shell-name))
  (get-buffer shell-name))


(defun shelly ()
  (interactive)
  (new-shell "shelly"))


(defun my-find-file-check-make-large-file-read-only-hook ()
  "If a file is over a given size, make the buffer read only."
  (when (> (buffer-size) (* 1024 1024 2))
    (setq buffer-read-only t)
    (buffer-disable-undo)
    (fundamental-mode)
    (display-line-numbers-mode -1)))

(add-hook 'find-file-hook 'my-find-file-check-make-large-file-read-only-hook)



(setq js-indent-level 2)
(defun beautify-json ()
  (interactive)
  (let ((b (if mark-active (min (point) (mark)) (point-min)))
        (e (if mark-active (max (point) (mark)) (point-max))))
    (shell-command-on-region b e
                             "python3 -mjson.tool" (current-buffer) t)))





(global-set-key (kbd "C-x g") 'magit-status)













;; Stuff for golang pry squad: START
;; This sets up for doing work on the qa box.
(defun pry-squad-tty ()
  ;; Watch out - the paths are wrong below
  (interactive)
  (let* (
         (name "*build*")
         (buf (new-shell name))
         (scp-shell (new-shell "*the-scp-shell*"))
         )
    (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 securepry-tty-srv/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //securepry-tty-srv/...\n")
    (with-current-buffer buf
      (highlight-phrase "INFO: Build completed successfully" "hi-green")

      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/securepry-" "hi-pink")
      )

    (process-send-string scp-shell
                         (concat "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && "
                                 "fswatch -o -r -0 ./bazel-bin/securepry-tty-srv/cmd/ | xargs -0 -n1 -I{} \ "
                                 "rsync -avz --rsync-path='sudo rsync'  \ "
                                 "bazel-bin/securepry-tty-srv/cmd/securepry-tty-srv/securepry-tty-srv_/securepry-tty-srv \ "
                                 "bazel-bin/securepry-tty-srv/cmd/securepry-container-sidecar-srv/securepry-container-sidecar-srv_/securepry-container-sidecar-srv \ "
                                 "azsorkin@$QA_PRY_BOX:/deploy/securepry-tty-srv/current/securepry-tty-srv\n"
                                 ))
    )
  )

;; TODO: should we make this configurable for qa / prod?
;; For the moment, let's keep it as QA.
;; TODO: tests!
;; cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 threat-ops-alerting/ | xargs -0 -n1 -I{} bazel test //threat-ops-alerting/core/slog/...
;; cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 threat-ops-alerting/ | xargs -0 -n1 -I{} bazel test //threat-ops-alerting/core/slog/... --sandbox_debug --test_output=all --features race
;; If want to only test for a single one, add in  --test_filter=TestFailingProducer


;; i-037785971f0015b59.sshbastion.pdx.qa.manage.stripe.net for the ssh-bastion.
;; Hm - bastion was giving me problems, bad hostname and all that.
;; peoplefe=i-09dcb4c3d4994c371.peoplefe.pdx.qa.manage.stripe.net




;; (defun my-run-on-save-hook (prefix buf-name cmd)
;;   (interactive "DDirectory Prefix:\nBBuffer Name for this to be executud in:\nsCommand:")
;;   (setq after-save-hook nil)
;;   ;; make the buffer if doesn't exist:
;;   (if (not (get-buffer buf-name))
;;       (new-shell buf-name))

;;   ;; prefix is usually ~/something/somewhere, but we need full path
;;   (lexical-let ((prefix (file-truename prefix)) (buf-name buf-name) (cmd cmd))
;;     (add-hook 'after-save-hook
;;               (lambda ()
;;                 (if (string-prefix-p prefix (buffer-file-name))
;;                     (with-current-buffer buf-name
;;                       (erase-buffer)
;;                       (process-send-string nil (concat cmd "\n"))
;;                       )
;;                   )
;;                 )
;;               )
;;     )
;;   )

;; this is not ideal, let's just have a command that takes effect on save

  ;; (setq after-save-hook nil)
;; prefix is usually ~/something/somewhere, but we need full path
;; ./bazel run //threat-ops-alerting/cmd/session-monitor-srv:go_default_test
;; can't do this also, else the bazel cache is cleared.

;; prod: i-079cc083e39a42df7.sessionmonitorbox.northwest.prod.stripe.io
;; qa: i-0a037c4a335ebc185.sessionmonitorbox.northwest.qa.stripe.io
;; should be able to run this on audit/monitor/threatbox if just need read access
(add-hook 'after-save-hook
          (lambda ()
            (with-current-buffer "*monitor*"
            (erase-buffer)
            (process-send-string nil " ./bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/cmd/session-monitor-srv/... && rsync -avz   ./bazel-bin/threat-ops-alerting/cmd/session-monitor-srv/session-monitor-srv_/session-monitor-srv azsorkin@mythreatbox--02216e64e50c0db16.northwest.stripe.io:/home/azsorkin\n")
            )
            )
          )
(setq after-save-hook nil)



(add-hook 'after-save-hook
          (lambda ()
            (with-current-buffer "*monitor*"
            (erase-buffer)
            (process-send-string nil " ./bazel test //threat-ops-alerting/cmd/session-monitor-srv:go_default_test\n")
            )
            )
          )


(add-hook 'after-save-hook
          (lambda ()
            (with-current-buffer "*monitor*"
            (erase-buffer)
            (process-send-string nil " ./bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/session-monitor-srv/cli:cli && rsync -avz   ./bazel-bin/threat-ops-alerting/session-monitor-srv/cli/cli_/cli azsorkin@i-079cc083e39a42df7.sessionmonitorbox.northwest.prod.stripe.io:/home/azsorkin\n")
            )
            )
          )
(setq after-save-hook nil)



(add-hook 'after-save-hook
          (lambda ()
            (with-current-buffer "shelly"
            (erase-buffer)
            (process-send-string nil "python -c 'import yaml, sys,pprint; pprint.pprint(yaml.safe_load(sys.stdin)[\"production\"])' <  config/session-monitor-srv.yaml \n")
            )
            )
          )


(setq after-save-hook nil)


;;
(add-hook 'after-save-hook
          (lambda ()
            (with-current-buffer "*work-horse*"
            (erase-buffer)
            (process-send-string nil " ./bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/cmd/session-monitor-srv/... && rsync -avz   ./bazel-bin/threat-ops-alerting/cmd/session-monitor-srv/session-monitor-srv_/session-monitor-srv azsorkin@i-003c0a15a7e1b4a70.sessionmonitorbox.northwest.qa.stripe.io:/home/azsorkin\n")
            )
            )
          )

(add-hook 'after-save-hook
          (lambda ()
            (with-current-buffer "*work-horse*"
            (erase-buffer)
            (process-send-string nil "./bazel run //threat-ops-alerting/cmd/session-monitor-srv:session-monitor-srv \n")
            )
            )
          )

(setq after-save-hook nil)


;; mysudo $(echo 'c3VkbyBzdQo=' | base64 --decode)


(add-hook 'after-save-hook
          (lambda ()
            (with-current-buffer "*build-and-scp-shell*"
              (erase-buffer)
              (process-send-string nil " ./bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/cmd/threat-import-srv:threat-import-srv && rsync -avz  bazel-bin/threat-ops-alerting/cmd/threat-import-srv/threat-import-srv_/threat-import-srv  azsorkin@qa-threatimportbox--05649d32d19085e07.northwest.stripe.io:/home/azsorkin/ \n")
              )
            )
          )
(setq after-save-hook nil)


(add-hook 'after-save-hook
          (lambda ()
            (with-current-buffer "*build-and-scp-shell*"
              (erase-buffer)
              (process-send-string nil " ./bazel run  //threat-ops-alerting/cmd/threat-import-srv:go_default_test  \n")
              )
            )
          )
(setq after-save-hook nil)




(defun lllllletsgo (binary)
  ;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Using-Interactive.html
  (interactive "sbinary (must live under threat-ops-alerting in gocode, e.g., `session-log-srv':")
  "
  This should allow, at a minimum, easier development.

  - current defaults
    - uses the qa mythreatbox (could update to prompt for host type)
  - prompts for binary to build


  "
  (let* (
         (default-directory "~/stripe/threat-ops-detection-rules/")
         (box (shell-command-to-string "pay -t qa-mythreatbox show-host")) ;; TODO(?): arg
         (build-name (concat "*" binary "-service-build*"))
         (rsync-name (concat "*" binary "-service-rsync*"))
         (build-shell (if (not (get-buffer build-name))
                  (new-shell build-name)
                (get-buffer build-name)))
         (rsync-shell (if (not (get-buffer rsync-name))
                          (new-shell rsync-name)
                        (get-buffer rsync-name)))
         ;; (replace-regexp-in-string "\n$" ""
         ;;                  (shell-command-to-string "cd ~/stripe/threat-ops-detection-rules && pay -t qa-mythreatbox show-host"))
         )

    (process-send-string build-shell (concat
                                      "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 threat-ops-alerting/ | xargs -0 -n1 -I{} ./bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/cmd/" binary "/...\n")
                         )
    (with-current-buffer build-shell
      (highlight-phrase "INFO: Build completed successfully" (intern "hi-green"))

      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/threat-ops-alerting" (intern "hi-pink"))
      )
    (process-send-string rsync-shell
                         (concat "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && "
                                 "fswatch -o -r -0 ./bazel-bin/threat-ops-alerting/cmd/"
                                 binary
                                 "/ | xargs -0 -n1 -I{} \ "
                                 "rsync -avz   \ "
                                 "./bazel-bin/threat-ops-alerting/cmd/"
                                 binary "/" binary " _/" binary ;;; yikes, not a fan of the bazel path

                                 "/ \ "
                                 "azsorkin@" box ":/home/azsorkin/\n"
                                 ))
    )
  )

;; (lllllletsgo)
;; (call-interactively 'lllllletsgo)

;; session-audit-box
;; qa-mythreatbox--0c3198a2ed0f9c0b5.northwest.stripe.io

;; how to develop

(defun sessionauditboxxxxxxxxx ()
  (interactive)

  (let* (
         (build-name "*service-build*")
         (rsync-name "*service-rsync*")
         (buf (if (not (get-buffer build-name))
                  (new-shell build-name)
                (get-buffer build-name)))
         (scp-shell (if (not (get-buffer rsync-name))
                        (new-shell rsync-name)
                      (get-buffer rsync-name)))
         (box "qa-mythreatbox--0e96d7455681a705d.northwest.stripe.io") ;; qa
         ;; (box "mythreatbox--0ac7bb6e52ca375c9.northwest.stripe.io") ;; production
         ;; Gettting the qa box from .azsorkin_profile right now.
         ;; (replace-regexp-in-string "\n$" ""
         ;;                  (shell-command-to-string "cd ~/stripe/threat-ops-detection-rules && pay -t qa-mythreatbox show-host"))
         )
    (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 threat-ops-alerting/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/cmd/session-audit-srv/...\n")
    (with-current-buffer buf
      (highlight-phrase "INFO: Build completed successfully" (intern "hi-green"))

      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/threat-ops-alerting" (intern "hi-pink"))
      )

;; fswatch -o -r -0 ./bazel-bin/threat-ops-alerting/cmd/session-audit-srv/ | xargs -0 -n1 -I{} rsync -avz   ./bazel-bin/threat-ops-alerting/cmd/session-audit-srv/session-audit-srv_/session-audit-srv azsorkin@i-0dfc1235511f60afe.sessionauditbox.northwest.qa.stripe.io:/home/azsorkin/
    (process-send-string scp-shell
                         (concat "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && "
                                 "fswatch -o -r -0 ./bazel-bin/threat-ops-alerting/cmd/session-audit-srv/ | xargs -0 -n1 -I{} \ "
                                 ;; "rsync -avz --rsync-path='sudo rsync'  \ "
                                 "rsync -avz   \ "
                                 "./bazel-bin/threat-ops-alerting/cmd/session-audit-srv/ \ "
                                 "azsorkin@" box ":/home/azsorkin/\n"
                                 ))
    )
  )




(defun sessionlogboxxxxxxxxx ()
  (interactive)

  (let* (
         (build-name "*service-build*")
         (rsync-name "*service-rsync*")
         (buf (if (not (get-buffer build-name))
                  (new-shell build-name)
                (get-buffer build-name)))
         (scp-shell (if (not (get-buffer rsync-name))
                        (new-shell rsync-name)
                      (get-buffer rsync-name)))
         (box "qa-mythreatbox--0e96d7455681a705d.northwest.stripe.io") ;; qa
         ;; (box "mythreatbox--0ac7bb6e52ca375c9.northwest.stripe.io") ;; production
         ;; Gettting the qa box from .azsorkin_profile right now.
         ;; (replace-regexp-in-string "\n$" ""
         ;;                  (shell-command-to-string "cd ~/stripe/threat-ops-detection-rules && pay -t qa-mythreatbox show-host"))
         )
    (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 threat-ops-alerting/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/cmd/session-log-srv/...\n")
    (with-current-buffer buf
      (highlight-phrase "INFO: Build completed successfully" (intern "hi-green"))

      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/threat-ops-alerting" (intern "hi-pink"))
      )

;; fswatch -o -r -0 ./bazel-bin/threat-ops-alerting/cmd/session-log-srv/ | xargs -0 -n1 -I{} rsync -avz   ./bazel-bin/threat-ops-alerting/cmd/session-log-srv/session-log-srv_/session-log-srv azsorkin@i-0dfc1235511f60afe.sessionlogbox.northwest.qa.stripe.io:/home/azsorkin/
    (process-send-string scp-shell
                         (concat "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && "
                                 "fswatch -o -r -0 ./bazel-bin/threat-ops-alerting/cmd/session-log-srv/ | xargs -0 -n1 -I{} \ "
                                 ;; "rsync -avz --rsync-path='sudo rsync'  \ "
                                 "rsync -avz   \ "
                                 "./bazel-bin/threat-ops-alerting/cmd/session-log-srv/ \ "
                                 "azsorkin@" box ":/home/azsorkin/\n"
                                 ))
    )
  )


;; HM - CAN WE BUILD THINGS LOCALLY (for tests) for both linux and darwin?

;; com_stripe_corp_git_stripe_internal_gocode/threat-ops-alerting -- highlihgt pink
;; FAILED TO BUILD - highlight pink



;; fswatch -o -r -0 ./threat-ops-alerting/ ./core/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/cmd/slog-collector-srv/...

;; fswatch -o -r -0 ./bazel-bin/threat-ops-alerting/cmd/slog-collector-srv | xargs -0 -n1 -I{} rsync -avz   bazel-bin/threat-ops-alerting/cmd/slog-collector-srv/slog-collector-srv_/slog-collector-srv azsorkin@qa-mythreatbox--0453f32b966a9a033.northwest.stripe.io:/home/azsorkin/bin/

;; tests: fswatch -o -r -0 . | xargs -0 -n1 -I{} bazel test //threat-ops-alerting/... --sandbox_debug --test_output=streamed  --test_filter=TestSyslogParsing
(defun slogggggg ()
  (interactive)
  (let* (
         (build-name "*slog-build*")
         (rsync-name "*slog-rsync*")
         (buf (if (not (get-buffer build-name))
                  (new-shell build-name)
                (get-buffer build-name)))
         (scp-shell (if (not (get-buffer rsync-name))
                        (new-shell rsync-name)
                      (get-buffer rsync-name)))
         ;; Gettting the qa box from .azsorkin_profile right now.
         ;; (replace-regexp-in-string "\n$" ""
         ;;                  (shell-command-to-string "cd ~/stripe/threat-ops-detection-rules && pay -t qa-mythreatbox show-host"))
         )
    (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 threat-ops-alerting/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/core/slog/...\n")
    (with-current-buffer buf
      (highlight-phrase "INFO: Build completed successfully" (intern "hi-green"))

      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/threat-ops-alerting" (intern "hi-pink"))
      )

    (process-send-string scp-shell
                         (concat "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && "
                                 "fswatch -o -r -0 ./bazel-bin/threat-ops-alerting/core/slog/ | xargs -0 -n1 -I{} \ "
                                 ;; "rsync -avz --rsync-path='sudo rsync'  \ "
                                 "rsync -avz   \ "
                                 "bazel-bin/threat-ops-alerting/core/slog/examples/ \ "
                                 "azsorkin@$QA_MYTHREATBOX:/home/azsorkin/bin/\n"
                                 ))
    )
  )




(defun fffffforwarder-slogggggg ()
  (interactive)
  (let* (
         (build-name "*slog-build*")
         (rsync-name "*slog-rsync*")
         (buf (if (not (get-buffer build-name))
                  (new-shell build-name)
                (get-buffer build-name)))
         (scp-shell (if (not (get-buffer rsync-name))
                        (new-shell rsync-name)
                      (get-buffer rsync-name)))
         ;; Gettting the qa box from .azsorkin_profile right now.
         ;; (replace-regexp-in-string "\n$" ""
         ;;                  (shell-command-to-string "cd ~/stripe/threat-ops-detection-rules && pay -t qa-mythreatbox show-host"))
         )
    (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 threat-ops-alerting/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //threat-ops-alerting/cmd/slog-forwarder-srv/...\n")
    (with-current-buffer buf
      (highlight-phrase "INFO: Build completed successfully" (intern "hi-green"))

      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/threat-ops-alerting" (intern "hi-pink"))
      )

    (process-send-string scp-shell
                         (concat "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && "
                                 "fswatch -o -r -0 ./bazel-bin/threat-ops-alerting/cmd/ | xargs -0 -n1 -I{} \ "
                                 ;; "rsync -avz --rsync-path='sudo rsync'  \ "
                                 "rsync -avz   \ "
                                 "bazel-bin/threat-ops-alerting/cmd/slog-forwarder-srv/slog-forwarder-srv_/slog-forwarder-srv \ "
                                 "azsorkin@$QA_MYTHREATBOX:/home/azsorkin/bin/\n"
                                 ))
    )
  )




                                 ;; "bazel-bin/threat-ops-alerting/slog/examples/simplist/simplist_/simplist \ "
                                 ;; "bazel-bin/threat-ops-alerting/slog/examples/drop-events/drop-events_/drop-events \ "
                                 ;; "bazel-bin/threat-ops-alerting/slog/examples/skip-kafka/skip-kafka_/skip-kafka \ "
                                 ;; "bazel-bin/threat-ops-alerting/slog/examples/server/server_/server \ "


;; kafka-tail security.debug_threat_detection --cluster primary --cluster kafkapub-northwest-green --cluster kafkapub-northwest-green --cluster kafkapub-northwest-sage





;; TODO: should we make this configurable for qa / prod?
;; For the moment, let's keep it as QA.
;; (defun my-log-stuff ()
;;   (interactive)
;;   (let* (
;;          (build-name "*logggg-build*")
;;          (buf (if (not (get-buffer build-name))
;;                   (new-shell build-name)
;;                 (get-buffer build-name)))
;;          )
;;     (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 garbage/ | xargs -0 -n1 -I{} bazel build  //garbage/...\n")
;;     (with-current-buffer buf
;;       (highlight-phrase "INFO: Build completed successfully" "hi-green")

;;       (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/garbage" "hi-pink")
;;       )
;;     )
;;   )










;; Stuff for golang pry squad: START
;; This sets up for doing work on the qa box.
(defun pry-squad-mongo ()
  ;; Watch out - the paths are wrong below
  (interactive)
  (let* (
         (name "*build*")
         (buf (new-shell name))
         (scp-shell (new-shell "*the-scp-shell*"))
         )
    (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 mproxy/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //mproxy/cmd/securepry-mproxy/...\n")
    (with-current-buffer buf
      (highlight-phrase "INFO: Build completed successfully" "hi-green")

      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/securepry-" "hi-pink")
      )

    (process-send-string scp-shell
                         (concat "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && "
                                 "fswatch -o -r -0 ./bazel-bin/mproxy/cmd/ | xargs -0 -n1 -I{} \ "
                                 "rsync -avz --rsync-path='sudo rsync'  \ "
                                 "bazel-bin/mproxy/cmd/securepry-mproxy/securepry-mproxy_/securepry-mproxy \ "
                                 "azsorkin@$QA_PRY_BOX:/deploy/securepry-mproxy/current/mproxy/securepry-mproxy\n"
                                 ))
    )
  )




;; N.B.: Moved to production
(defun pry-squad-tls ()
  (interactive)
  (let* (
         (name "*build*")
         (buf (new-shell name))
         (scp-shell (new-shell "*the-scp-shell*"))
         )
    (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 securepry-tls-proxy/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //securepry-tls-proxy/...\n")
    (with-current-buffer buf
      (highlight-phrase "INFO: Build completed successfully" "hi-green")

      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/securepry-" "hi-pink")
      )

    (process-send-string scp-shell
                         (concat "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && "
                                 "fswatch -o -r -0 ./bazel-bin/securepry-tls-proxy/ | xargs -0 -n1 -I{} \ "
                                 "rsync -avz --rsync-path='sudo rsync'  \ "
                                 "bazel-bin/securepry-tls-proxy/securepry-tls-proxy_/securepry-tls-proxy \ "
                                 "azsorkin@$QA_PRY_BOX:/deploy/securepry-tls-proxy/current/\n"
                                 ))
    )
  )


(defun pry-squad-secrets ()
  (interactive)
  (let* (
         (name "*build*")
         (buf (new-shell name))
         (scp-shell (new-shell "*the-scp-shell*"))
         )
    (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 securepry-secrets-srv/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //securepry-secrets-srv/...\n")
    (with-current-buffer buf
      (highlight-phrase "INFO: Build completed successfully" "hi-green")

      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/securepry-" "hi-pink")
      )

    (process-send-string scp-shell
                         (concat "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && "
                                 "fswatch -o -r -0 ./bazel-bin/securepry-secrets-srv/ | xargs -0 -n1 -I{} \ "
                                 "rsync -avz --rsync-path='sudo rsync'  \ "
                                 "bazel-bin/securepry-secrets-srv/securepry-secrets-srv_/securepry-secrets-srv \ "
                                 "azsorkin@$QA_PRY_BOX:/deploy/securepry-secrets-srv/current/\n"
                                 ))
    )
  )

  ;;
;; Stuff for golang pry squad: END






;; (desktop-save-mode 1)
;; (setq desktop-restore-eager 1)
;; (setq desktop-path '("~/.emacs.d/" "~" "~/stripe/"))
;; Hmm, notice that our path is ~/.emacs.d/, and the desktop file there is .emacs.desktop
;; So: i think we need to open in that directory to get it to work





;; Note: For this to work, need to update preferences ⌘-,
;; and then go to `keyboard` and remove the existing mapping
;; that sets ESC-<right> and ESC-<left> to M-f and M-b
;; see https://emacs.stackexchange.com/a/47353
(global-unset-key (kbd "ESC <up>"))
(global-unset-key (kbd "ESC <down>"))

(global-set-key (kbd "ESC <up>") 'windmove-up)
(global-set-key (kbd "ESC <down>") 'windmove-down)
(global-unset-key (kbd "ESC <left>"))
(global-set-key (kbd "ESC <left>") 'windmove-left)
(global-unset-key (kbd "ESC <right>"))
(global-set-key (kbd "ESC <right>") 'windmove-right)





(defun az/pbcopy-region (beg end)
  "Copy region to the local macOS clipboard, including from TRAMP buffers."
  (interactive "r")
  (unless (use-region-p)
    (user-error "No active region"))
  (let ((default-directory temporary-file-directory))
    (unless (zerop (call-process-region beg end "/usr/bin/pbcopy" nil nil nil))
      (user-error "pbcopy failed")))
  (message "Copied region to local clipboard"))

(global-set-key (kbd "C-c y") 'az/pbcopy-region)




 ;; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; (setq gnutls-algorithm-priority nil)
;; (add-to-list 'package-archives '("smelpa" . "http://melpa.org/packages/") t)

;; Initialize the package system
(require 'package)

;; Add MELPA to your package archives
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;; PERFORMANCE: Skip signature checking (faster but less secure)
(setq package-check-signature nil)

;; PERFORMANCE: Don't auto-refresh on startup - do it manually when needed
;; To manually refresh: M-x package-refresh-contents
;; Uncomment if you need automatic refresh:
;; (unless package-archive-contents
;;   (package-refresh-contents))

;; Check if use-package is installed (for Emacs < 29), install if not
(unless (package-installed-p 'use-package)
  (package-refresh-contents)  ;; Only refresh if we actually need to install
  (package-install 'use-package))

;; Load use-package
(require 'use-package)







;; this adds to startup time
;; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; (add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
;; (add-to-list 'package-archives
;;              '("melpa-stable" . "https://stable.melpa.org/packages/") t)
;; (add-to-list 'package-archives '("gnu" . "http://orgmode.org/elpa/") t)

(package-initialize)



;; PERFORMANCE: Load theme after init for faster startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (when (display-graphic-p)
              (load-theme 'solarized-dark t)
              (set-face-attribute 'default nil :height 140)
              ;; (set-frame-size (selected-frame) 206 61)  ;; This is for on macbook
              (set-frame-size (selected-frame) 175 86)  ;; this is with external monitor
              (menu-bar-mode t))))

(setq org-todo-keywords
      '((sequence "TODO(!)" "IN-PROGRESS(!)" "NEEDS-APPROVAL(!)" "|" "DONE(!)" "WONT-FIX(!)" )))

(setq org-todo-keyword-faces
      '(("WONT-FIX" . (:foreground "yellow"  :weight bold))
        ("NEEDS-APPROVAL" . (:foreground "brightblack"  :weight bold))
        ("IN-PROGRESS" . (:foreground "blue" :weight bold))))





(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(setq use-package-always-ensure t)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (js . t)
   (lisp . t)
   (python . t)
   (ruby . t)
   (shell . t)
   )
 )
(setq org-babel-python-command "python3")

(require 'org-tempo) ;; to make <s-TAB work.






;; https://flow.org/en/docs/editors/emacs/
;; cd ~/.emacs.d/
;; git clone https://github.com/flowtype/flow-for-emacs.git
;; echo -e "\n(load-file \"~/.emacs.d/flow-for-emacs/flow.el\")" >> ~/.emacs
;; TODO: commenting this out right now, as it overwrites M-. -> flow-get-def in go code
;; (load-file "~/.emacs.d/flow-for-emacs/flow.el")



(use-package puppet-mode :defer t)
(use-package typescript-mode :defer t)
(use-package dockerfile-mode :defer t)


(use-package clang-format :defer t)
(use-package clang-format+ :defer t)

(use-package php-mode :defer t)

(use-package groovy-mode :defer t)
(use-package exec-path-from-shell
  :defer t
  :if (eq system-type 'darwin)
  :custom
  (exec-path-from-shell-check-startup-files nil)
  (exec-path-from-shell-variables '("PATH"
                                    "MANPATH"
                                    "GOPATH"))
  :config
  (exec-path-from-shell-initialize))
;; TODO: . ~/.bash_profile


(use-package yaml-mode :defer t)
(use-package terraform-mode :defer t)


;; Unable to find
;; (use-package markdown-mode :ensure t
;;   ;; :hook visual-line-mode ;; TODO: this doesn't work
;;   )  ;; Oddly enough we do need the :ensure t
;; (use-package markdown-mode+ :ensure t
;;   ;; :hook visual-line-mode  ;;
;;   ) ;; Same

;; (add-hook 'markdown-mode-hook 'visual-line-mode)


(use-package ruby-mode
  :config
  (defun my-ruby-mode-hook ()
    (set-fill-column 80)
    (add-hook 'before-save-hook 'delete-trailing-whitespace nil 'local)
    (setq ruby-insert-encoding-magic-comment nil))
  (add-hook 'ruby-mode-hook 'my-ruby-mode-hook))


;; Set up LSP
;; Hint: use M-. to go to a definition, and M-, to go back.
;; PERFORMANCE: LSP is VERY slow to start. Only enable if you really need it.
;; Uncomment the lines below to enable LSP for Ruby:
;; (use-package lsp-mode :defer t :commands lsp)
;; (use-package lsp-ui :defer t :commands lsp-ui-mode)
;; (use-package company-lsp :defer t :commands company-lsp)
;; (add-hook 'ruby-mode-hook #'lsp)
;; (add-hook 'enh-ruby-mode-hook #'lsp)
;; (setq lsp-prefer-flymake :none)
;; (setq lsp-log-io t)
;; (setq lsp-enable-snippet nil)

;; Decides if the buffer is Ruby and in pay server
(defun activate-pay-server-sorbet-p (filename mode)
  (and
   (string-prefix-p (expand-file-name "~/stripe/pay-server")
                    filename)
   (or (eq major-mode 'ruby-mode) (eq major-mode 'enh-ruby-mode))))

(setq stripe-username "azsorkin")


(use-package solarized-theme :defer t)

(use-package scala-mode :defer t)
(use-package json-mode :defer t)

(use-package csv-mode :defer t)

;; Cannot find
;; (use-package bazel-mode)

(use-package go-mode :defer t)


(use-package deadgrep
  :defer t
  :bind (("C-x a" . deadgrep)))

;; Possible todo: open file when have just relative path (e.g., from shell)
;;





;; Frontend
(use-package web-mode
  :init
  ;; (defun web-mode-customization ()
  ;;   "Customization for web-mode."
  ;;   (setq web-mode-markup-indent-offset 2)
  ;;   (setq web-mode-attr-indent-offset 2)
  ;;   (setq web-mode-css-indent-offset 2)
  ;;   (setq web-mode-code-indent-offset 2)
  ;;   (setq web-mode-enable-auto-pairing t)
  ;;   (setq web-mode-enable-css-colorization t)
  ;;   (add-hook 'before-save-hook 'delete-trailing-whitespace nil 'local))
  ;; (add-hook 'web-mode-hook 'web-mode-customization)

          (setq web-mode-markup-indent-offset 2)
          (setq web-mode-css-indent-offset 2)
          (setq web-mode-code-indent-offset 2)
          (setq web-mode-attr-indent-offset 2)


  :mode ("\\.html?\\'" "\\.erb\\'" "\\.hbs\\'"
         "\\.jsx?\\'" "\\.json\\'" "\\.s?css\\'" "\\.tsx?\\'"
         "\\.less\\'" "\\.sass\\'"))


(defun get-eslint-executable ()
  (let ((root (locate-dominating-file
                (or (buffer-file-name) default-directory)
                "package.json")))
    (and root
         (expand-file-name "node_modules/eslint/bin/eslint.js"
                           root))))

;; (defun my/use-eslint-from-node-modules ()
;;   (let ((eslint (get-eslint-executable)))
;;     (when (and eslint (file-executable-p eslint))
;;       (setq flycheck-javascript-eslint-executable eslint))))
;; (use-package company-flow
;;   :config
;;   (add-to-list 'company-backends 'company-flow))

(defun get-flow-executable ()
  (let ((root (locate-dominating-file
                (or (buffer-file-name) default-directory)
                "package.json")))
    (and root
         (expand-file-name "node_modules/flow-bin/cli.js"
                           root))))



;; (use-package flow-minor-mode)
;; ;; (add-hook 'web-mode-hook 'flow-minor-mode)  ;; TODO



;; (defun my/use-flow-from-node-modules ()
;;   (let ((flow (get-flow-executable)))
;;     (when (and flow (file-exists-p flow))
;;       (setq flycheck-javascript-flow-executable flow))))
;; (use-package flycheck-flow)
;; (defun enable-minor-mode (my-pair)
;;   (if (buffer-file-name)
;;     (if (string-match (car my-pair) buffer-file-name)
;;       (funcall (cdr my-pair)))))


;; TODO: re-enable this once we are done with the gocode issues
(use-package prettier-js
  :defer t
  :init
  ;; (add-hook 'web-mode-hook #'(lambda () (enable-minor-mode '("\\.jsx?\\'" . prettier-js-mode)))))
  )

;; (remove-hook 'web-mode-hook #'(lambda () (enable-minor-mode '("\\.jsx?\\'" . prettier-js-mode))))

;; TODO:
;; Space commander necessary work
;; $ rubocop <filename>






;; Tools
(use-package company
  :defer t
  :hook (prog-mode . company-mode))
;; (use-package projectile
;;   :init
;;   (setq projectile-indexing-method 'alien)
;;   (setq projectile-use-git-grep t)
;;   (setq projectile-tags-command "/usr/local/bin/ctags --exclude=node_modules --exclude=admin --exclude=.git --exclude=frontend --exclude=home --exclude=**/*.js -Re -f \"%s\" %s")

;;   :config
;;   (projectile-global-mode))

;; (use-package helm
;;   :bind (("M-x" . helm-M-x))
;;   :config
;;   (require 'helm-config)
;;   (helm-mode 1)
;;   )


;; (use-package helm-projectile
;;   :init
;;   (setq helm-projectile-fuzzy-match nil)
;;   :config
;;   (helm-projectile-on))

;; (use-package flycheck
;;   :init
;;   (setq flycheck-ruby-rubocop-executable "bundle exec rubocop")
;;   (setq flycheck-ruby-executable (format "/Users/%s/.rbenv/shims/ruby" "azsorkin"))
;;   :config
;;   (setq-default flycheck-disabled-checkers
;;                 (append flycheck-disabled-checkers
;;                         '(javascript-jshint)
;;                         '(ruby-rubylint)
;;                         '(json-jsonlist)
;;                         '(emacs-lisp-checkdoc)))

;;   (add-hook 'flycheck-mode-hook #'my/use-eslint-from-node-modules)
;;   (add-hook 'flycheck-mode-hook #'my/use-flow-from-node-modules)

;;   ;; use eslint and flow with web-mode for jsx files
;;   (flycheck-add-mode 'javascript-eslint 'web-mode)
;;   (flycheck-add-mode 'javascript-flow 'web-mode)
;;   (flycheck-add-next-checker 'javascript-flow '(t . javascript-eslint))

;;   ;; (global-flycheck-mode)
;; )


;; disable flycheck for go-mode
;; until I figure out how to have flycheck also
;; look at autogenerated files

(setq debug-on-error t)

;; (setq flycheck-disabled-checkers '(go-mode))


;; (defun my-disable-flycheck ()
;;   (when (and (eq major-mode 'go-mode))
;;     (flycheck-mode -1)))
;; (add-hook 'flycheck-mode-hook #'my-disable-flycheck)


(use-package magit
  :defer t
  :bind (("C-c m s" . magit-status)))

(use-package thrift :defer t)
(use-package protobuf-mode :defer t)


;; TODO
;; (add-to-list 'auto-mode-alist '("BUILD\\'" . bazel-mode))

(add-to-list 'auto-mode-alist '("\\.pp\\'" . puppet-mode))
(add-to-list 'auto-mode-alist '("\\.rbi\\'" . ruby-mode))

(add-to-list 'auto-mode-alist '("\\.sky\\'" . python-mode))

(add-to-list 'auto-mode-alist '("\\.azsorkin_profile\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\.stripe_profile\\'" . sh-mode))

(add-to-list 'auto-mode-alist '("\\.aspx\\'" . web-mode))

(defun my-go-mode-hook ()
  (local-set-key (kbd "M-.") 'godef-jump)
  (local-set-key (kbd "M-*") 'pop-tag-mark)
  (subword-mode +1)
  )
(add-hook 'go-mode-hook 'my-go-mode-hook)

(use-package go-eldoc :defer t)
;; (add-hook 'go-mode-hook 'go-eldoc-setup) ;; TODO: this is failing



(use-package apples-mode :defer t)
(add-to-list 'auto-mode-alist '("\\.\\(applescri\\|sc\\)pt\\'" . apples-mode))

(use-package go-autocomplete :ensure t :defer t)
(setq gofmt-command "/Users/azsorkin/go/bin/goimports")
;; PERFORMANCE: Only run gofmt on Go files, not all files
(defun my-gofmt-before-save ()
  "Run gofmt only for Go files."
  (when (eq major-mode 'go-mode)
    (gofmt-before-save)))
(add-hook 'before-save-hook 'my-gofmt-before-save)

;; Disable flycheck for go-mode
(global-hl-line-mode 0)

;; single spaces only
(defun single-spaces-only (beg end)
  "replace all whitespace in the region with single spaces"
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region beg end)
      (goto-char (point-min))
      (while (re-search-forward "\\s-+" nil t)
        (replace-match " ")))))

;; someday :smile: - will refactor to have stripe-specific code here.
(load "~/.emacs.d/my-private.el" 'missing-ok)


(defun stripe-develop-hook ()
  ;; On save, if a ruby file, run (from ~/stripe/pay-server/)
  ;; scripts/bin/rubocop <filename>
  ;; e.g., $ scripts/bin/rubocop status_site/lib/services/generate_full_json.rb
  ;; Some work for stripe *admin* apps
  ;; https://frontend.stripe.me/docs/admin-apps-yarn-admin
  ;; To run frontend admin tests (replace "status_site" with name of app)
  ;; (anywhere-in-payserver) $ yarn admin test status_site
  ;; To lint
  ;; (anywhere-in-payserver) $ yarn admin lint status_site
  ;; To flow
  ;; (anywhere-in-payserver) $ yarn admin flow status_site
  ;; caution: :point-up: runs over entire thing - need to filter properly
  (cond
   ((string-prefix-p "/Users/azsorkin/stripe/pay-server" (buffer-file-name))

    ;; Moreover, likely will end up with additional things for subdirs of payserver
    ;; status site front end:
    ;; run `yarn generate` in /Users/azsorkin/stripe/pay-server/status_site/generate
    ;; Need to run
    ;; ./admin/assets/scripts/ci-flow.sh
    ;; when changing js in go/admin (e.g., status_site admin js
    ;;  for impact-srv
    ;; in impact/assets, running
    ;; yarn lint components/Panels/EventStats.jsx  --fix
    ;; will lint and fix.
    (when
        (string= (symbol-name major-mode) "ruby-mode")
      (start-process "rubocop" "rubocop"  "~/stripe/pay-server/scripts/bin/rubocop.rb" (buffer-file-name))
      ;; TODO: another test to write pay test --with-changed-files test/wholesome/always_run/no_rubocop_errors.rb -n '/test_test.unit.dev.lib.pry_ext.commands.upload_file.rb.passes.rubocop/'

      ;; it is such garbage that I cannot do this:
      ;; (start-process "ruby-lint" "ruby-lint"  "~/stripe/pay-server/scripts/bin/lint" " -n " (buffer-file-name))
      (let ((ruby-lint "ruby-lint")
            (pay-server-location "/Users/azsorkin/stripe/pay-server"))

        (if (not (member ruby-lint (mapcar (lambda (buffer) (buffer-name buffer))
                                           (buffer-list))))

            (new-shell ruby-lint)
          )
        (if (not (string= (pwd) pay-server-location))
            (process-send-string ruby-lint "cd /Users/azsorkin/stripe/pay-server\n"))
        ;; (erase-buffer)
        ;; (process-send-string nil (concat "script/bin/lint" " -n " (substring (buffer-file-name) (length pay-server-location))) "\n")))
        (process-send-string ruby-lint (concat "./scripts/bin/lint"
                                               " -n "
                                               (substring
                                                (buffer-file-name)
                                                (+ 1
                                                   (length pay-server-location)))
                                               "\n"))

        )
      )

    ;; (if (string-suffix-p ".js" (buffer-file-name))
    ;;     (start-process "yarn-generate" "yarn-generate"  "" (buffer-file-name))
    ;;   )
    )

   ;; learning golang here
   ((string-prefix-p "/Users/azsorkin/go/src/exercises.from.golang.book/" (buffer-file-name))
    (with-current-buffer "shelly"
      (erase-buffer)
      (process-send-string nil "go build -o main\n")
      (process-send-string nil "./main\n"))
    ;; (start-process "go build /Users/azsorkin/exercises-from-goloang-book/ch2/conversion.go && ./conversion 100")

    (start-process "vetting-process" "vetting-process" "go" "vet" "/Users/azsorkin/go/src/exercises.from.golang.book/ch3/mandlebrot")
    )

   ((string-prefix-p "/Users/azsorkin/stripe/space-commander" (buffer-file-name))
    ;; todo: this should be by major-mode

    ;; https://confluence.corp.stripe.com/display/DND/Space+Commander+Development+Guide
    ;; reminder: commit by running
    ;;
    ;; git fetch
    ;; git checkout master
    ;; git reset --hard origin/master-passing-tests
    ;; git merge --no-ff $your_branch
    ;; git push origin

    (if (string-match-p ".*command.*" (buffer-file-name))
        (start-process "rubocop" "rubocop"  "rubocop" (buffer-file-name))
      )

    )

   ((string-prefix-p "/Users/azsorkin/stripe/puppet_config" (buffer-file-name))
    ;; How to terraform
    ;; 1. Need phone (for MFA)
    ;; 2. To create a detector in signalfx (using signal-flow
    ;; 3. After writing code, use `sc-terraform plan` - note: this is for the entire module
    ;; To scope to a single file, use `--target module.detectors.signalform_detector.signalform_detector_status_site_5xx - note: this is not path-to-file!
    ;; To apply changes: sc-terraform apply ...
    ;; Once applied, code can be merged in, and you are done!
    ;; sc-terraform apply --target  module.detectors.signalform_detector.signalform_detector_status_site_5xx

    ;; Need to run `sc-terraform fmt <file>` if file is a terraform (e.g., main.tf) file
    ;; But - the sc-terraform fmt is janky: need to run in the proper directory, and use full path name for file!
    ;; E.g., run
    ;; sc-terraform fmt ~/stripe/puppet-config/terraform/stripe.io/signalfx/developer-tooling/detectors/securepry_low_usable_memory.tf
    ;; in location
    ;; ~/stripe/puppet-config/terraform/stripe.io/signalfx/developer-tooling/detectors/

    )
  )
)

;; To use: call in file where we want to run things, need to know command.
(defvar my-run-on-save-commands nil
  "Registered run-on-save commands as (PREFIX BUFFER-NAME COMMAND).")

(defun my-run-on-save--normalize-prefix (prefix)
  "Return PREFIX as a canonical directory name for prefix matching."
  (file-name-as-directory (file-truename (expand-file-name prefix))))

(defun my-run-on-save--remove-command (prefix buf-name)
  "Remove the run-on-save command for PREFIX and BUF-NAME."
  (setq my-run-on-save-commands
        (delq nil
              (mapcar (lambda (entry)
                        (unless (and (equal (nth 0 entry) prefix)
                                     (equal (nth 1 entry) buf-name))
                          entry))
                      my-run-on-save-commands))))

(defun my-run-on-save--run-command (buf-name cmd)
  "Run CMD in BUF-NAME, creating the shell buffer if needed."
  (unless (get-buffer buf-name)
    (new-shell buf-name))
  (with-current-buffer buf-name
    (erase-buffer)
    (let ((proc (get-buffer-process (current-buffer))))
      (if proc
          (process-send-string proc (concat cmd "\n"))
        (message "my-run-on-save-hook: no process in buffer %s" buf-name)))))

(defun my-run-on-save--dispatch ()
  "Run commands registered by `my-run-on-save-hook' for the saved file."
  (when buffer-file-name
    (let ((filename (file-truename (expand-file-name buffer-file-name))))
      (dolist (entry my-run-on-save-commands)
        (let ((prefix (nth 0 entry))
              (buf-name (nth 1 entry))
              (cmd (nth 2 entry)))
          (when (string-prefix-p prefix filename)
            (my-run-on-save--run-command buf-name cmd)))))))

(defun my-run-on-save-hook (prefix buf-name cmd)
  (interactive "DDirectory Prefix:\nBBuffer Name for this to be executed in:\nsCommand: ")
  (let ((prefix (my-run-on-save--normalize-prefix prefix)))
    (my-run-on-save--remove-command prefix buf-name)
    (push (list prefix buf-name cmd) my-run-on-save-commands)
    (add-hook 'after-save-hook #'my-run-on-save--dispatch)
    (unless (get-buffer buf-name)
      (new-shell buf-name))
    (message "my-run-on-save-hook: will run `%s' in %s after saves under %s"
             cmd buf-name prefix)))

(defun my-run-on-save-clear ()
  "Clear all commands registered by `my-run-on-save-hook'."
  (interactive)
  (setq my-run-on-save-commands nil)
  (remove-hook 'after-save-hook #'my-run-on-save--dispatch)
  (message "my-run-on-save-hook: cleared registered commands"))

;; (add-hook 'after-save-hook
;;           (lambda ()
;;             (with-current-buffer "shelly"
;;               (erase-buffer)
;;               (process-send-string nil (concat "go run main.go"  "\n"))
;;               )
;;             )
;;           )

;; (setq after-save-hook nil)


(defun my-threatbox ()
  ;; Sync stuff
  (interactive)
  (let* (
         ;; (name "*")
         ;; (buf (new-shell name))
         (rsync-shell (new-shell "*the-puppet-rsync-shell*"))
         ;; (my-threatbox (substring
         ;;                (shell-command-to-string "pay -t qa-mythreatbox show-host")
         ;;                0 -1)
         ;;               )
         )
    ;; (process-send-string buf "cd ~/go/src/git.corp.stripe.com/stripe-internal/gocode/ && fswatch -o -r -0 securepry-tty-srv/ | xargs -0 -n1 -I{} bazel build --platforms=@io_bazel_rules_go//go/toolchain:linux_amd64 //securepry-tty-srv/...\n")
    ;; (with-current-buffer buf
    ;;   (highlight-phrase "INFO: Build completed successfully" "hi-green")

    ;;   (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/securepry-" "hi-pink")
    ;;   )
    (process-send-string rsync-shell
                         (concat "cd ~/stripe/puppet-config && "
                                 "fswatch -o -r -0 ./ | xargs -0 -n1 -I{} \ "
                                 "rsync -avz --rsync-path='sudo rsync' --exclude=.git --exclude=terraform  ./ "
                                 (concat "azsorkin@" "qa-mythreatbox--0f2e30842d8a77a65.northwest.stripe.io" ":/pay/puppet-masterless/  \n")
                                 ))
    )
  )

;; How to squash 3 commits into 1 commit:
;; git reset --soft HEAD~3 && git commit



(defun stripe-develop ()
  (interactive)
  ;; dips
  ;;
  (add-hook 'after-save-hook 'stripe-develop-hook)
  )

(defun STOP-stripe-develop ()
  (interactive)
  (remove-hook 'after-save-hook 'stripe-develop-hook)
  )




;; TODO: some of this should be moved to my-private.el
(defun dev-brb ()
  "Get set to do brb development: this automates a few steps in development.md
   - run mongo server in buffer *brb-mongo-server*
   - run dev in buffer *brb-dev-serve*

  TODO
  1) Test/Linting
   a) in the assets directory, run
   `$assets> ../../../bin/yarn lint`
   (and also possibly yarn flow. this is needed for the frontend assets)

   b) in top level, $ make test.


  2) Can we make the *brb-dev-serve* better
     for example: '
     -- automatically show in the message pane if there is an error?




"
  (interactive)
  ;; Note: using __ as prefix for mongo-server
  ;; Since I almost never want to tab into that buffer
  (let ((mongo "*__brb-mongo-server__*")
        (dev "*brb-dev-serve*"))

    ;; idempotent: kill buffers if exist, and kill mongod
    (when (get-buffer mongo)
      (kill-buffer mongo))

    (when (get-buffer dev)
      (kill-buffer dev))
    (shell-command "pkill mongod")
    ;; TODO: refactor shelly to be useful here
    (with-current-buffer (new-shell mongo)
      (process-send-string nil "mongod --dbpath ~/localbrb\n"))

    (with-current-buffer (new-shell dev)
      (highlight-phrase "com_stripe_corp_git_stripe_internal_gocode/incident-reporting-srv" 'hi-blue)

      (process-send-string nil "cd ~/stripe/gocode/incident-reporting-srv\n")
      (process-send-string nil "make dev\n"))
    )
  (message "Ready to develop BRB"))



;; TODO: some of this should be moved to my-private.el
(defun end-brb ()

  (interactive)
  ;; Note: using __ as prefix for mongo-server
  ;; Since I almost never want to tab into that buffer
  (let ((mongo "*__brb-mongo-server__*")
        (dev "*brb-dev-serve*"))

    ;; idempotent: kill buffers if exist, and kill mongod
    (when (get-buffer mongo)
      (kill-buffer mongo))

    (when (get-buffer dev)
      (kill-buffer dev))
    (shell-command "pkill mongod")
  (message "ended")))



;; To search all buffers
;;  C-u M-x multi-occur-in-matching-buffers
;; .*
;; <string-to-search-for>


(defun az/chomp (s)
  (replace-regexp-in-string "[\r\n]+\\'" "" s))

(defun az/file-first-line (file)
  (when (file-readable-p file)
    (with-temp-buffer
      (insert-file-contents file nil 0 4096)
      (az/chomp (buffer-substring-no-properties
                 (point-min)
                 (line-end-position))))))

(defun az/git-packed-ref (git-dir ref)
  (let ((packed-refs (expand-file-name "packed-refs" git-dir)))
    (when (file-readable-p packed-refs)
      (with-temp-buffer
        (insert-file-contents packed-refs)
        (goto-char (point-min))
        (when (re-search-forward
               (concat "^\\([0-9a-f]+\\) " (regexp-quote ref) "$")
               nil
               t)
          (match-string 1))))))

(defun az/git-common-dir (git-dir)
  (let ((commondir (az/file-first-line (expand-file-name "commondir" git-dir))))
    (if commondir
        (file-name-as-directory (expand-file-name commondir git-dir))
      git-dir)))

(defun az/git-resolve-ref (git-dir ref)
  (let* ((common-dir (az/git-common-dir git-dir))
         (branch (when (string-match "\\`refs/heads/\\(.+\\)\\'" ref)
                   (match-string 1 ref)))
         (candidate-refs (append
                          (list ref)
                          (when branch
                            (list (concat "refs/remotes/origin/" branch)))))
         (candidate-dirs (list git-dir common-dir)))
    (catch 'found
      (dolist (candidate-ref candidate-refs)
        (dolist (candidate-dir candidate-dirs)
          (let ((ref-file (expand-file-name candidate-ref candidate-dir)))
            (let ((sha (az/file-first-line ref-file)))
              (when sha
                (throw 'found sha)))
            (let ((sha (az/git-packed-ref candidate-dir candidate-ref)))
              (when sha
                (throw 'found sha)))))))))

(defun az/stripe-git-ref-from-root (root)
  (condition-case nil
      (let* ((git-entry (expand-file-name ".git" root))
             (git-dir (cond
                       ((file-directory-p git-entry) git-entry)
                       ((file-readable-p git-entry)
                        (let ((line (az/file-first-line git-entry)))
                          (when (and line (string-match "\\`gitdir: \\(.+\\)\\'" line))
                            (expand-file-name (match-string 1 line) root)))))))
        (when git-dir
          (let ((head (az/file-first-line (expand-file-name "HEAD" git-dir))))
            (cond
             ((not head) nil)
             ((string-match "\\`ref: \\(.+\\)\\'" head)
              (az/git-resolve-ref git-dir (match-string 1 head)))
             (t head)))))
    (error nil)))

(defun az/tramp-like-localname (file)
  (or (file-remote-p file 'localname)
      (when (string-match "\\`/[^:]+:[^:]+:\\(/.*\\)\\'" file)
        (match-string 1 file))))

(defun az/tramp-like-prefix (file)
  (or (file-remote-p file)
      (when (string-match "\\`\\(/[^:]+:[^:]+:\\)/.*\\'" file)
        (match-string 1 file))))

(defun az/stripe-repo-context-for-buffer ()
  (let* ((remote-local-file (az/tramp-like-localname buffer-file-name))
         (remote-prefix (or (az/tramp-like-prefix buffer-file-name) ""))
         (local-file (or remote-local-file (file-truename buffer-file-name)))
         (contexts `(("/pay/src/" . "mint")
                     ("/Users/azsorkin/stripe/mint/" . "mint")
                     ("/Users/azsorkin/go/src/git.corp.stripe.com/stripe-internal/gocode/" . "gocode"))))
    (catch 'found
      (dolist (context contexts)
        (let ((root (car context))
              (repo (cdr context)))
          (when (string-prefix-p root local-file)
            (throw 'found
                   (list repo
                         (concat remote-prefix root)
                         (substring local-file (length root)))))))
      (when (string-prefix-p "/Users/azsorkin/stripe/" local-file)
        (let* ((stripe-root "/Users/azsorkin/stripe/")
               (rest (substring local-file (length stripe-root)))
               (repo (car (split-string rest "/")))
               (root (concat stripe-root repo "/")))
          (throw 'found
                 (list repo
                       (concat remote-prefix root)
                       (substring local-file (length root))))))
      (user-error "Don't know how to build a Stripe Git URL for %s" buffer-file-name))))

(defun open-file-in-github ()
  (interactive)
  (unless buffer-file-name
    (user-error "Current buffer is not visiting a file"))
  (let* ((line-number (number-to-string (line-number-at-pos)))
         (repo-context (az/stripe-repo-context-for-buffer))
         (repo-name (nth 0 repo-context))
         (repo-root (nth 1 repo-context))
         (relative-path (nth 2 repo-context))
         (git-ref (or (az/stripe-git-ref-from-root repo-root) "master"))
         (url (concat "https://git.corp.stripe.com/stripe-internal/"
                      repo-name
                      "/blob/"
                      git-ref
                      "/"
                      relative-path
                      "#L"
                      line-number)))
    (let ((default-directory temporary-file-directory))
      (browse-url url))))

(global-set-key (kbd "C-x j") 'open-file-in-github)
(global-set-key (kbd "C-x C-j") 'open-file-in-github)


(defun xml-pretty-print (beg end &optional arg)
  "Reformat the region between BEG and END.
    With optional ARG, also auto-fill."
  (interactive "*r\nP")
  (let ((fill (or (bound-and-true-p auto-fill-function) -1)))
    (sgml-mode)
    (when arg (auto-fill-mode))
    (sgml-pretty-print beg end)
    (nxml-mode)
    (auto-fill-mode fill)))

(put 'narrow-to-region 'disabled nil)



(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(case-fold-search t)
 '(inhibit-startup-echo-area-message nil)
 '(package-selected-packages
   '(0blayout apples-mode clang-format+ company csv-mode deadgrep
              dockerfile-mode exec-path-from-shell gh-md
              go-autocomplete go-eldoc groovy-mode json-mode lsp-ui
              magit php-mode prettier-js protobuf-mode puppet-mode
              scala-mode solarized-theme terraform-mode thrift
              typescript-mode web-mode yaml-mode))
 '(safe-local-variable-values
   '((gotest-ui-additional-test-args "-tags" "dev")
     (go-test-args . " -tags dev")
     (go-rename-command . "gorename -tags dev"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(put 'erase-buffer 'disabled nil)
