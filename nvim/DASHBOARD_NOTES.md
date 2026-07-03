# Neovim Dashboard And Org-Roam Notes

This file captures the decisions, preferences, and implementation details from the dashboard and Org-roam work.

## Goal

Make the Neovim start screen productive instead of decorative.

The dashboard should reduce friction in the first few seconds of opening Neovim by helping with:

- opening today's daily note
- surfacing relevant TODOs
- resuming coding work
- showing git context
- keeping the layout clean and stable

## User Preferences

### General

- Keep the dashboard useful, not flashy.
- Prefer productivity over filler.
- Avoid ASCII art-heavy sections unless they are already part of the existing dashboard style.
- Avoid clutter.

### What To Keep

- `Today's note`
- `Todo`
- `Recent Files`
- `Projects`
- `Git Snapshot`
- `Resume Work`

### What To Avoid

- no generic `Actions` section
- no `Notes` title above `Today's note`
- no fleeting note on the dashboard if it is a different concept from daily note
- no extra Neovim keybind for fleeting note
- no decorative dashboard items like quotes, weather, or clocks

### Layout Preferences

- `Today's note` should appear directly, not under a `Notes` heading.
- `Todo` should keep its title.
- `Todo` belongs in the left pane.
- `Resume Work` should be clearly separated from `Today's note`.
- resume file entries should be left-aligned
- right pane content must not bump into the left pane
- project entries should stay compact so the layout remains stable even if more projects are added

## Org-Roam Notes Setup

The goal was to reuse the existing Org-roam workflow instead of inventing a second daily-note system.

### Daily Notes

- Daily notes live under `~/notes/roam/daily/YYYY-MM-DD.org`
- today's note should be available directly from the dashboard
- missing daily notes should be auto-created
- the daily template was updated to better match the richer structure used elsewhere

### Fleeting Notes

- fleeting notes already existed in the Org-roam setup
- a temporary extra keybind was added during experimentation
- that extra keybind was removed because it was not wanted
- fleeting note was removed from the dashboard because it is distinct from daily note

## Dashboard Decisions

### Final Feature Direction

The dashboard should answer these questions:

- what should I do now
- where was I
- what repo was I working in
- what is today's note

### Current Sections

Left pane:

- `Today's note`
- `Resume Work`
- `Todo`

Right pane:

- `Git Snapshot`
- `Recent Files`
- `Projects`

### Why These Sections Exist

#### Today's Note

- starts the day quickly
- ties the dashboard into the existing Org-roam daily workflow
- avoids a separate note system

#### Todo

- shows Org TODO items directly on the dashboard
- sorts higher-priority work first
- gives quick access to task locations

#### Resume Work

- points at the most recent non-notes coding project
- opens the last file in that project
- shows a few recent files from that same project below it

#### Git Snapshot

- shows the active repo and branch for the selected coding project
- summarizes working tree state
- gives one direct action into git status

#### Projects

- lists recent code projects
- excludes note repos
- is intentionally compact

## Todo Behavior

### Source

TODOs are collected from Org agenda files under the Org-roam notes tree.

### Visibility

- the `Todo` section only appears when matching TODOs exist

### Matching Rules

- must be an Org heading
- must start with `TODO`
- archived entries are ignored
- empty placeholder titles are ignored

### Sorting

Current ordering:

1. `[#A]`
2. `[#B]`
3. `[#C]`
4. no recognized priority after those

Tie-breakers:

1. newer file first
2. earlier line in the file

### Rendering

- TODOs appear in the left pane
- TODO items show visible numeric keys
- selecting a TODO opens the file and jumps to the heading

## Resume Work Behavior

### Project Selection

`Resume Work` prefers:

1. the most recent non-notes git project found in oldfiles
2. if none exist, a fallback project context

### What It Shows

- one primary action: open the last file in the selected project
- a short list of recent files from the same project below it

### Important Display Decision

- resume file entries are informational
- they are left-aligned
- long paths are shortened so the section stays inside its pane

## Git Snapshot Behavior

### Source

Uses the same recent coding project context as `Resume Work`.

### What It Shows

- project name
- branch
- working tree summary

Possible summary values include:

- `clean working tree`
- staged count
- modified count
- untracked count
- conflicted count

## Projects Section Behavior

The built-in Snacks `projects` section was not a good fit for this layout because it renders project entries as `file` items, which creates width pressure and caused the right pane to collide with the left pane.

That was replaced with a custom projects section that:

- shows short project names instead of long paths
- keeps project actions working
- excludes note repos
- is safer if more projects are added later

## Layout And Rendering Fixes

Several layout issues were found and corrected.

### Fixes Made

- removed the generic `Actions` section
- removed the `Notes` heading
- kept the `Todo` heading
- moved `Todo` into the left pane
- added spacing between `Today's note` and `Resume Work`
- made resume entries left-aligned
- tightened description widths so text does not bleed across panes
- increased pane gap
- shortened long dashboard text where needed
- replaced the built-in `Projects` section with a compact custom one

### Rendering Constraints Learned

Snacks assigns autokeys globally across the dashboard, not per section.

That means:

- keys remain unique across the entire screen
- section-local numbering is not automatic

Also:

- if a dashboard item has a `label`, Snacks shows that instead of the autokey
- this is why TODOs originally did not show numeric keys until the label usage was corrected

## Files Touched

Primary files involved in the work:

- `~/.config/nvim/lua/plugins/snacks-dashboard.lua`
- `~/.config/nvim/lua/plugins/org-roam.lua`
- `~/.config/nvim/lua/config/org_roam.lua`
- `~/notes/roam/daily/2026-04-02.org`

## Current Dashboard Intent

The dashboard should feel like a workspace resume screen, not a launcher menu.

The intended mental model is:

- open today's note
- see the highest-value TODOs
- resume the repo you were actually working on
- see whether that repo is dirty

## Ideas Discussed For Later

These were considered useful additions, but not all were implemented:

- `Agenda Today`
- smarter `Todo` or `Next Up`
- `Dirty Files`
- `Scratch`
- `Context Snapshot`
- `Focus 3`

The strongest future additions were:

1. `Agenda Today`
2. `Git Snapshot` improvements
3. a stronger `Resume Work` flow, possibly session-first

## Current Open Improvement Ideas

Reasonable next steps from here:

1. make the recent files under `Resume Work` individually selectable
2. compact `Recent Files` further so the whole right pane uses the same shorter style
3. add ahead/behind counts to `Git Snapshot`
4. add `Agenda Today` from Org data
5. make Org priority sorting generic across `A` through `Z` instead of only treating `A`, `B`, and `C` specially

## Short Version

The dashboard is now centered around your existing Org-roam workflow and recent coding context.

The stable direction is:

- direct daily-note access
- visible prioritized TODOs
- clear resume-work block
- compact git context
- compact recent projects
- minimal extra noise
