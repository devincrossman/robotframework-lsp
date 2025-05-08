# [Language Server Protocol](https://github.com/Microsoft/language-server-protocol) implementation for [Robot Framework](https://robotframework.org/)

This is a fork of the original [Robocorp robotframework-lsp monorepo](https://github.com/robocorp/robotframework-lsp).

## About this Fork

This fork is being developed and maintained solely to apply updates and fixes that align with our specific use case and to ensure compatibility with the latest versions of [Robot Framework](https://robotframework.org/).

## Features (1.13.0)

-   Robot Output View:
    -   View current task/test being executed.
    -   Shows Keyword being executed in real time.
-   Robot Documentation View:
    -   Select a library import for the full library documentation.
    -   Select another element for its docstring.
-   Test Explorer support in VSCode.
-   Interactive Console: a REPL for interactively experimenting with Robot Framework (for VSCode).
-   Code analysis:
    -   Keywords/variables.
    -   Keyword arguments.
-   Linting with [Robocop](https://robocop.readthedocs.io/en/latest/).
-   Code completion:
    -   Keywords, variables, sections and snippets.
    -   Auto imports from keywords in the workspace.
-   Go to definition:
    - Keywords, variables and imports.
-   Find references for keywords and variables.
-   Refactoring:
    -   Rename keywords.
    -   Rename variables.
    -   Extract local variable.
    -   Extract variable to variables section.
-   Quick fixes (VSCode: `Ctrl + .`):
    -   Add import for unresolved keyword.
    -   Create local variable for unresolved variable.
    -   Create argument for unresolved variable.
    -   Creat variable in variables section for unresolved variable.
    -   Assign keyword to variable.
    -   Surround with Try..Except.
-   Symbols browser for keywords in workspace (VSCode: `Ctrl + T`).
-   Document symbols (VSCode: `Ctrl + Shift + O`).
-   Highlight of keywords and variables.
-   Syntax highlighting (using `semanticTokens`).
-   Syntax validation.
-   Signature Help (VSCode: `Ctrl + Shift + Space`).
-   Code Formatting (see: [Editor Settings](https://code.visualstudio.com/docs/getstarted/settings#_language-specific-editor-settings) for details on how to toggle code formatting just for `robotframework`).
-   Hover.
-   Code folding.
-   Launch `.robot` files.
-   Debugger:
    -   Add line breakpoints in `.robot` or `.py` files
    -   Break on log error/failure
    -   Evaluate keywords in debug console/hover/watch
    -   Pause at breakpoints to inspect the stack and see variables
    -   Breakpoint condition/hitCondition/logMessage
    -   Step in
    -   Step over
    -   Step return
    -   Continue

See: [Changelog](docs/changelog.md) for details.

## License: Apache 2.0
