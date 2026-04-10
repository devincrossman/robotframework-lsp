Packaging notes
---------------

This fork does not publish from GitHub Actions.

The GitHub workflow only builds artifacts for validation:

- Python source and wheel distributions from `robotframework-ls/src/dist`
- A VS Code extension package at `robotframework-ls/robotframework-lsp.vsix`

For the current local packaging flow, see [BUILDING.md](../../BUILDING.md).

If you want to cut a manual release:

- Update the version with `python -m dev set-version <version>`
- Update `README.md` and `docs/changelog.md`
- Run the packaging flow from [BUILDING.md](../../BUILDING.md)
- Validate the generated wheel, sdist, and VSIX locally
- Publish artifacts manually wherever you intend to distribute them
