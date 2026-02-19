# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-02-20

### Added

- `AnchoredPaginatedList<T>` widget with bidirectional pagination and variable-height items
- `AnchoredPaginatedListController` with `jumpTo`, `animateTo`, `jumpToKey`, and `animateToKey`
- Automatic scroll anchoring when items are prepended — the viewport stays on the same content
- Two-phase scroll correction (`correctBy` + `jumpToItem`) to prevent visual flash on backward pagination
- Built-in loading, error, and empty state builders
- Reverse mode (`reverse: true`) for chat-like UIs
- `visibleRange` on the controller for visible index inspection
- Reset of stale pagination state when the entire item window is replaced (search / deep-link flow)
- Example app with a 10k-message chat simulator, windowed search, and bidirectional pagination
