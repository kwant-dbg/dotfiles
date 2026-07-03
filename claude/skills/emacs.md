---
name: emacs
description: Emacs, Doom Emacs, doom configuration and troubleshooting. Triggered by requests about emacs, doom, doom emacs, configure packages, setup org-mode/org-roam, fix elisp errors, install packages, keybindings, or any Emacs-related operations. Handles both Doom's module system and vanilla package.el workflows.
---

# Emacs Skill

## Purpose
Provide expert guidance on Emacs configuration, package management, and troubleshooting for both Doom Emacs and vanilla Emacs setups. Understand the differences between configuration systems and apply appropriate solutions.

## Trigger Phrases
- "doom" / "doom emacs" / "doom config"
- "configure [package] in emacs" / "configure [package] in doom"
- "setup org-roam" / "install org-noter"
- "emacs config" / "emacs configuration"
- "fix [elisp error]"
- "how to use [emacs feature]"
- "emacs keybinding for [action]" / "doom keybinding"
- "doom sync" / "doom doctor" / "doom upgrade"
- "config.el" / "init.el" / "packages.el"
- Any request involving Emacs, Doom, packages, or elisp

## Core Capabilities

### 1. Detect Emacs Flavor
**Always determine which Emacs setup the user has:**

```bash
# Check for Doom Emacs
ls ~/.config/emacs/init.el ~/.config/doom/ ~/.doom.d/

# Check for vanilla Emacs
ls ~/.emacs ~/.emacs.d/init.el ~/.config/emacs/init.el
```

**Doom Emacs indicators:**
- `~/.config/emacs/` with `modules/` subdirectory
- `~/.doom.d/` or `~/.config/doom/` config directory
- Files: `init.el`, `packages.el`, `config.el`

**Vanilla Emacs indicators:**
- `~/.emacs` or `~/.emacs.d/init.el`
- Direct `use-package` or `package.el` usage

### 2. Doom Emacs Configuration Pattern

**File Structure:**
```
~/.config/doom/
├── init.el       # Enable/disable modules
├── packages.el   # Declare packages
└── config.el     # Personal settings
```

**Workflow:**
1. **Enable modules** in `init.el`:
   ```elisp
   (doom! :tools
          pdf               ; enable pdf-tools
          :lang
          (org +roam))      ; enable org with roam flag
   ```

2. **Add packages** in `packages.el`:
   ```elisp
   (package! org-noter)
   (package! org-roam-ui)
   ```

3. **Configure** in `config.el`:
   ```elisp
   (after! org-roam
     (setq org-roam-directory "~/notes/"))
   ```

4. **Apply changes:**
   ```bash
   ~/.config/emacs/bin/doom sync
   ```

5. **Restart Emacs**

**Key Doom Macros:**
- `after!` - Configure after package loads
- `use-package!` - Declare and configure package
- `map!` - Define keybindings
- `add-hook!` - Add hooks

### 3. Vanilla Emacs Configuration Pattern

**File Structure:**
```
~/.emacs.d/
└── init.el       # All configuration here
```

**Workflow:**
1. **Setup package manager** in `init.el`:
   ```elisp
   (require 'package)
   (setq package-archives '(("melpa" . "https://melpa.org/packages/")
                            ("gnu" . "https://elpa.gnu.org/packages/")))
   (package-initialize)

   (unless (package-installed-p 'use-package)
     (package-refresh-contents)
     (package-install 'use-package))
   ```

2. **Install and configure packages:**
   ```elisp
   (use-package org-roam
     :ensure t
     :custom
     (org-roam-directory "~/notes/")
     :config
     (org-roam-db-autosync-mode))
   ```

3. **Reload config:**
   ```
   M-x eval-buffer
   ```
   or restart Emacs

### 4. Common Package Configurations

#### Org-Roam Setup
```elisp
;; Doom - Keybindings OUTSIDE after! block to avoid timing issues
(map! :leader
      :desc "Roam find note"
      "r f" #'org-roam-node-find
      :desc "Roam insert link"
      "r i" #'org-roam-node-insert
      :desc "Roam backlinks"
      "r b" #'org-roam-buffer-toggle
      :desc "Roam daily note"
      "r d" #'org-roam-dailies-capture-today)

(after! org-roam
  (setq org-roam-directory "~/notes/roam/")
  (setq org-roam-dailies-directory "daily/")
  (org-roam-db-autosync-mode))

;; Vanilla
(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory "~/notes/roam/")
  :bind (("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert))
  :config
  (org-roam-db-autosync-mode))
```

#### Org-Roam Dailies with Custom Templates
```elisp
;; Doom - Custom capture templates for dailies
(after! org-roam
  (setq org-roam-dailies-directory "daily/")
  (setq org-roam-dailies-capture-templates
        '(("d" "default" entry
           "* %<%H:%M> %?"
           :target (file+head "%<%Y-%m-%d>.org"
                              "#+title: %<%A, %B %d, %Y>\n#+filetags: :daily:\n"))

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
                              "#+title: %\1\n#+filetags: :meeting:\n")
           :unnamedp t))))

;; Key template syntax:
;; %^{prompt} - Interactive input, first one is %\1, second is %\2, etc.
;; %<%format> - Time format using strftime syntax
;; %? - Cursor position after capture
;; :unnamedp t - Create standalone file (plain) instead of entry
;; file+head - Create file with front matter if it doesn't exist
```

#### Bidirectional Auto-linking for Org-Roam
```elisp
;; Automatically link meetings to daily notes bidirectionally
(after! org-roam
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

  (add-hook 'org-capture-after-finalize-hook #'my/org-roam-meeting-link-to-daily))

;; How it works:
;; 1. Hook triggers after meeting capture finishes
;; 2. Checks if today's daily note exists (creates if needed)
;; 3. Finds "* 🔗 Connections" heading in daily note
;; 4. Appends link to meeting
;; 5. Meeting already has link to daily in "Related" section
;; Result: True bidirectional linking
```

#### Org-Noter + PDF Tools
```elisp
;; Doom (add to packages.el first)
(use-package! org-noter
  :after (:any org pdf-view)
  :config
  (setq org-noter-notes-search-path (list org-roam-directory))
  (setq org-noter-auto-save-last-location t))

;; Vanilla
(use-package pdf-tools
  :ensure t
  :config
  (pdf-tools-install))

(use-package org-noter
  :ensure t
  :after (:any org pdf-view)
  :custom
  (org-noter-notes-search-path '("~/notes/"))
  (org-noter-auto-save-last-location t))
```

### 5. Troubleshooting Workflows

#### Package Not Found
```bash
# Doom
doom sync
doom doctor  # Check for issues

# Vanilla
M-x package-refresh-contents
M-x package-install RET package-name
```

#### Configuration Not Loading
```elisp
;; Check load order - use after! in Doom
(after! package-name
  ;; config here
  )

;; Check package is actually installed
M-x describe-package RET package-name

;; Reload config
M-x doom/reload  ; Doom
M-x eval-buffer  ; Vanilla
```

#### Keybinding Conflicts
```elisp
;; Check what's bound to a key
C-h k <key-sequence>

;; In Doom, use map! to override
(map! :leader
      :desc "My command"
      "x" #'my-command)

;; In vanilla, use bind-key
(bind-key "C-c x" #'my-command)
```

### 6. Best Practices

#### File Organization
- **Doom**: Keep module configs in `config.el`, never edit core files
- **Vanilla**: Split large configs into multiple files:
  ```elisp
  (load "~/.emacs.d/org-config.el")
  (load "~/.emacs.d/keybindings.el")
  ```

#### Performance
```elisp
;; Defer package loading
(use-package some-package
  :defer t
  :commands (some-command))

;; Lazy load on file type
(use-package markdown-mode
  :mode "\\.md\\'")

;; Lazy load on hook
(use-package flycheck
  :hook (prog-mode . flycheck-mode))
```

#### Safe Configuration Paths
```elisp
;; Use file-truename for symlinks
(setq org-roam-directory (file-truename "~/notes/roam/"))

;; Expand ~/ properly
(setq my-directory (expand-file-name "~/my-files/"))

;; Check directory exists
(unless (file-directory-p org-roam-directory)
  (make-directory org-roam-directory t))
```

### 7. Debugging Elisp

#### Check Variables
```
M-x describe-variable RET variable-name
C-h v variable-name
```

#### Check Functions
```
M-x describe-function RET function-name
C-h f function-name
```

#### View Keybindings
```
M-x describe-key RET <press-key>
C-h k <press-key>
```

#### View All Bindings for Mode
```
M-x describe-mode
C-h m
```

#### Evaluate Elisp
```elisp
;; Eval last sexp
C-x C-e

;; Eval region
M-x eval-region

;; Eval buffer
M-x eval-buffer
```

### 8. Common Pitfalls to Avoid

1. **Don't mix Doom and vanilla syntax** in same config
2. **Don't use `~/.emacs.d/init.el` with Doom** - it won't load
3. **Always run `doom sync`** after changing `packages.el`
4. **Use `after!` in Doom** instead of bare `use-package` for built-in packages
5. **Keybinding timing issues in Doom:**
   - Put `map!` keybindings OUTSIDE `after!` blocks to avoid "undefined" or "not a command" errors
   - Doom's `map!` with `#'` handles autoloading correctly
   - Only put configuration (setq, hooks, etc.) inside `after!` blocks
6. **Check package availability** before configuring:
   ```elisp
   (when (package-installed-p 'package-name)
     ;; config here
     )
   ```
7. **Use correct org-roam-dailies function names:**
   - `org-roam-dailies-capture-today` (correct - shows template menu)
   - NOT `org-roam-dailies-today` (internal function, not a command)

### 9. Quick Reference Commands

#### Doom
```bash
doom sync          # Sync packages and rebuild
doom upgrade       # Upgrade Doom and packages
doom doctor        # Diagnose issues
doom env           # Refresh environment
```

#### Package Management
```
M-x package-list-packages    # Browse packages
M-x package-install          # Install package
M-x package-delete           # Remove package
M-x package-refresh-contents # Update package list
```

#### Help System
```
C-h k    # describe-key
C-h f    # describe-function
C-h v    # describe-variable
C-h m    # describe-mode
C-h b    # describe-bindings
C-h a    # apropos (search help)
```

## Integration Guidelines

When configuring Emacs features:

1. **Detect environment first** (Doom vs vanilla)
2. **Read existing config** before suggesting changes
3. **Use appropriate syntax** for the detected environment
4. **Test changes incrementally** (eval-buffer before full restart)
5. **Provide both workflows** if user environment is unclear
6. **Explain WHY** certain approaches work better in each environment

## Example Interaction Pattern

User: "Setup org-noter"

Response:
1. Check if Doom or vanilla Emacs
2. Check if pdf-tools already configured
3. Check if org-roam is installed (for integration)
4. Provide appropriate config snippet
5. Show sync/reload commands
6. Give quick usage example
7. Link to relevant documentation

Always prefer reading existing config over assuming configuration state.
