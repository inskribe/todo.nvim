
# todo.nvim

A Neovim plugin for collecting and displaying structured TODO comments across your current buffer, all loaded buffers, or your entire project — with powerful fuzzy searching via Telescope.

---

## Features

- Parse `TODO::` comments from single- and multi-line comments
- Treesitter-powered syntax tree scanning
- Project-wide TODO discovery via root markers
- Telescope fuzzy picker integration
- Cleans up multiline block comments into concise messages
- Supports categories like `TODO::Category` that allow for quick searching

---

## Installation

**lazy.nvim**

```lua
{
  "inskribe/todo.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {
    -- defaults to cwd
    -- root_markers = {".git", "go.mod", "Makefile"}
  }
}
```

> Note: `todo.nvim` currently uses Telescope to handle displaying todos and goto functionality.  
> More options will come soon.

---

## Configuration

```lua
opts = {
  root_markers = { ".git", "go.mod", "Makefile" }, -- default
}
```

- `root_markers`: Identifiers used to find the project root directory.

---

## Usage

After installation, the following commands are available:

| Command          | Description                                   |
|------------------|-----------------------------------------------|
| `:CurrentTodos`  | Collect TODOs in the current buffer            |
| `:LoadedTodos`   | Collect TODOs in all currently loaded buffers  |
| `:ProjectTodos`  | Collect TODOs from all project files           |

Each picker entry will open the file and jump directly to the TODO location.

---

## TODO Comment Format

The plugin targets comments that start with `TODO::`, supporting both inline and block comment styles.

### Supported Styles

```go
// TODO::Auth Fix login edge case
// todo::Feature add new feature
/* TODO::Sendgrid
 * Setup email credentials
 * and check sandbox behavior
 */
```

### Smart Parsing

Multiline block comments are automatically de-indented, asterisks are stripped, and newlines are joined.

Example:

```go
/*
 * TODO::Payments
 * Audit stripe integration
 * Confirm webhook delivery
 */
```

Becomes:

```
Payments:: Audit stripe integration Confirm webhook delivery
```

If no category is provided, it defaults to `Missing category`.

> In multiline `TODO` comments, all pointer references `*` will be preserved.

Example:
```go
/*
 * TODO::Memory
 * Change fetchLargeData to return *LargeData
 * to avoid unnecessary memory spikes.
 */
```

Becomes:

```
Memory:: Change fetchLargeData to return *LargeData to avoid unnecessary memory spikes.
```

---

## Filetype Support

Currently, `project`-level searches look for `.go`  files using `fd`.

> More languages will be supported soon.

---

## Inspiration

Inspired by the need for categorized, cleanly formatted, and project-aware TODOs in modern codebases — without depending on LSP diagnostics or complex comment parsers.

---

