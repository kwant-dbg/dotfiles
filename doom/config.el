;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;; Font is controlled by WezTerm, not Emacs, in terminal mode
;; To change font: WezTerm config → font = wezterm.font("JetBrains Mono")

;; Ligatures disabled — requires graphical Emacs with Harfbuzz
;; (use-package! ligature
;;   :config
;;   (ligature-set-ligatures 'prog-mode '(...))
;;   (global-ligature-mode t))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(server-start)

(setq doom-theme 'kanagawa-dragon)

(custom-set-faces!
  '(doom-modeline-bar :background "#504945")  ; muted brown bar
  '(mode-line :background "#32302f" :foreground "#a89984")
  '(mode-line-inactive :background "#282828" :foreground "#665c54"))


;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/notes/org/")
(setq org-roam-directory "~/notes/roam/")

;; Org-agenda configuration - scan daily notes for TODOs
(setq org-agenda-files '("~/notes/roam/daily/"))

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(after! evil-escape
  (setq evil-escape-key-sequence "jk"
        evil-escape-delay 0.2))


;; Org-roam keybindings
(map! :leader
      :desc "Roam find note"
      "r f" #'org-roam-node-find
      :desc "Roam insert link"
      "r i" #'org-roam-node-insert
      :desc "Roam backlinks"
      "r b" #'org-roam-buffer-toggle
      :desc "Roam UI (interactive graph)"
      "r g" #'org-roam-ui-mode
      :desc "Roam daily note"
      "r d" #'org-roam-dailies-capture-today
      :desc "Roam add tag"
      "r a" #'org-roam-tag-add)

(after! org-roam
  ;; Zettelkasten capture templates
  (setq org-roam-capture-templates
        '(("f" "Fleeting note" plain "%?"
           :target (file+head "fleeting/${slug}.org"
                              "#+title: ${title}\n#+filetags: :fleeting:\n#+date: %<%Y-%m-%d>\n")
           :unnamedp t)

          ("l" "Literature note" plain
           "* Source\n- Author: %^{Author}\n- Title: %^{Source Title}\n- Year: %^{Year}\n\n* Summary\n%?\n\n* Key Ideas\n- \n\n* Quotes\n- "
           :target (file+head "literature/${slug}.org"
                              "#+title: ${title}\n#+filetags: :literature:\n#+date: %<%Y-%m-%d>\n")
           :unnamedp t)

          ("p" "Permanent note" plain
           "\n\n* Related Notes\n- %?"
           :target (file+head "permanent/${slug}.org"
                              "#+title: ${title}\n#+filetags: :permanent:\n#+date: %<%Y-%m-%d>\n")
           :unnamedp t)))

  ;; Daily notes for quick fleeting captures
  (setq org-roam-dailies-directory "daily/")
  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry
           "* %<%H:%M> %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%A, %B %d, %Y>
#+filetags: :daily:
#+date: %<%Y-%m-%d>

* ✅ Tasks
Use SPC m , to set priority [#A] [#B] [#C] after creating a TODO

** TODO [#A] %?
** TODO [#B]
** TODO [#C]

** DONE

* 💭 Thoughts
Journal entries, notes, and reflections throughout the day.

** %<%H:%M>


* 🔗 Connections
Links to other notes, ideas, or resources discovered today.


* 🌙 Reflection
- What went well today?
- What could be improved?
- Tomorrow's focus:
"))

           ("q" "quick note" entry
            "* %<%H:%M> %?"
            :target (file+head "%<%Y-%m-%d>.org"
                               "#+title: %<%A, %B %d, %Y>\n#+filetags: :daily:\n#+date: %<%Y-%m-%d>\n"))

           ("m" "meeting" plain
            "* Meeting: %^{Meeting Title}
:PROPERTIES:
:DATE: %<%Y-%m-%d %H:%M>
:ATTENDEES: %^{Attendees}
:END:

** Notes
%?

** Action Items
- [ ]

** Related
- [[file:daily/%<%Y-%m-%d>.org][Daily Note: %<%Y-%m-%d>]]
"
            :target (file+head "../meetings/%<%Y-%m-%d> - %\1.org"
                               "#+title: %\1\n#+filetags: :meeting:\n#+date: %<%Y-%m-%d>\n")
            :unnamedp t)))

  ;; Auto-link meetings to daily notes bidirectionally
  (defun my/org-roam-meeting-link-to-daily ()
    "After capturing a meeting, add a link to it in the corresponding daily note."
    (when (and (org-roam-capture-p)
               (equal (org-capture-get :key) "m"))
      (let* ((meeting-file (buffer-file-name))
             (meeting-title (org-get-title))
             (date-string (format-time-string "%Y-%m-%d"))
             (daily-file (expand-file-name
                         (concat date-string ".org")
                         (expand-file-name org-roam-dailies-directory org-roam-directory))))
        ;; Create daily note if it doesn't exist
        (unless (file-exists-p daily-file)
          (org-roam-dailies--capture (current-time) t))
        ;; Add link to the daily note's Connections section
        (with-current-buffer (find-file-noselect daily-file)
          (goto-char (point-min))
          (when (re-search-forward "^\\* 🔗 Connections" nil t)
            (forward-line 1)
            (unless (looking-at "^$")
              (end-of-line)
              (insert "\n"))
            (insert (format "- [[file:../meetings/%s][Meeting: %s]]\n"
                          (file-name-nondirectory meeting-file)
                          meeting-title))
            (save-buffer))))))

  (add-hook 'org-capture-after-finalize-hook #'my/org-roam-meeting-link-to-daily)

  (org-roam-db-autosync-mode))

;;; Org-Mode Visual Enhancements

(after! org
  ;; Typography & Heading Hierarchy
  (custom-set-faces!
   '(org-document-title :height 1.6 :weight bold :foreground "#c34043")
   '(org-level-1 :height 1.4 :weight bold :foreground "#c4746e")
   '(org-level-2 :height 1.3 :weight semi-bold :foreground "#8ba4b0")
   '(org-level-3 :height 1.2 :weight semi-bold :foreground "#8ea4a2")
   '(org-level-4 :height 1.1 :weight semi-bold :foreground "#a292a3")
   '(org-level-5 :height 1.0 :weight semi-bold :foreground "#c4b28a")
   '(org-level-6 :height 1.0 :weight normal :foreground "#87a987")
   '(org-level-7 :height 1.0 :weight normal :foreground "#8ba4b0")
   '(org-level-8 :height 1.0 :weight normal :foreground "#938aa9")

   ;; Emphasis faces
   '(org-bold :weight bold :foreground "#c4746e")
   '(org-italic :slant italic :foreground "#8ba4b0")
   '(org-underline :underline t :foreground "#8ea4a2")
   '(org-verbatim :foreground "#87a987" :background "#1a1a1a")
   '(org-code :foreground "#c4b28a" :background "#1a1a1a")
   '(org-strikethrough :strike-through t :foreground "#625e5a"))

  (defun my/org-emphasis-colors ()
    "Remap standard emphasis faces in org buffers only."
    (face-remap-add-relative 'bold :foreground "#e46876")
    (face-remap-add-relative 'italic :foreground "#7fb4ca")
    (face-remap-add-relative 'underline :foreground "#7aa89f"))

  (add-hook 'org-mode-hook #'my/org-emphasis-colors)

  (setq org-hide-emphasis-markers t
        org-ellipsis " ▾"
        org-startup-indented t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-src-preserve-indentation nil)

  (add-hook 'org-mode-hook #'visual-line-mode))

;; Org-Superstar: Beautiful bullets and TODO icons
(use-package! org-superstar
  :after org
  :hook (org-mode . org-superstar-mode)
  :config
  (setq org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●")
        org-superstar-item-bullet-alist '((?* . ?•) (?+ . ?➤) (?- . ?–))
        org-superstar-leading-bullet ?\s
        org-superstar-leading-fallback ?\s
        org-superstar-todo-bullet-alist
        '(("TODO" . ?☐)
          ("NEXT" . ?✓)
          ("HOLD" . ?✋)
          ("WAIT" . ?⏳)
          ("KILL" . ?✗)
          ("DONE" . ?✓))))

;; Org-Modern: Clean, modern visual style
(use-package! org-modern
  :after org
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-block-fringe nil
        org-modern-block-name '("" . "")
        org-modern-table t
        org-modern-table-vertical 1
        org-modern-table-horizontal 0.2
        org-modern-tag t
        org-modern-priority t
        org-modern-todo t
        org-modern-timestamp t
        org-modern-hide-stars 'leading))

;; Org-Appear: Dynamic emphasis marker visibility
(use-package! org-appear
  :after org
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoemphasis t
        org-appear-autolinks t
        org-appear-autosubmarkers t
        org-appear-autoentities t
        org-appear-autokeywords t
        org-appear-inside-latex t))

;;; Dirvish: Modern dired replacement
(use-package! dirvish
  :init
  (dirvish-override-dired-mode)
  :config
  (setq dirvish-quick-access-entries
        '(("h" "~/" "Home")
          ("d" "~/Downloads/" "Downloads")
          ("y" "~/yum/" "Yum Project")
          ("n" "~/notes/" "Notes")
          ("r" "~/notes/roam/" "Roam")))
  (setq dirvish-mode-line-format
        '(:left (sort symlink) :right (omit yank index)))
  (setq dirvish-attributes
        '(all-the-icons collapse subtree-state vc-state git-msg))
  (setq delete-by-moving-to-trash t)
  (setq dired-listing-switches
        "-l --almost-all --human-readable --group-directories-first --no-group"))

(after! dirvish
  (setq dirvish-hide-details t))

(map! :leader
      :desc "Open dirvish" "d d" #'dirvish
      :desc "Dirvish side" "d s" #'dirvish-side)

;;; Org-Roam UI: Interactive graph visualization
(use-package! org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-toggle t))

;;; Terminal Clickable UI
(xterm-mouse-mode 1)
(context-menu-mode 1)

;;; Mermaid Diagrams - Text-based diagramming
(use-package! ob-mermaid
  :after org
  :config
  ;; Path to mermaid CLI (install with: npm install -g @mermaid-js/mermaid-cli)
  (setq ob-mermaid-cli-path "mmdc")
  ;; Enable mermaid in org-babel
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((mermaid . t))))
