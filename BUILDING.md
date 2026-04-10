# Building

Verified local build flow for this repo on Windows/PowerShell.

From the repo root you can also run the scripted build entrypoint:

```powershell
.\build.ps1
```

Or from `cmd.exe`:

```bat
build.bat
```

This repo produces two build artifacts:

- The Python language server package from `robotframework-ls/src`
- The VS Code extension `.vsix` from `robotframework-ls`

## Prerequisites

From the repo root:

1. Initialize the debug adapter submodule:

```powershell
git submodule update --init --recursive
```

This is required. Without it, `robotframework-ls/src/setup.py sdist bdist_wheel --universal` fails because `robotframework-ls/src/robotframework_debug_adapter/vendored/vendored_pydevd` is empty.

2. Create and use a normal venv:

```powershell
py -m venv .venv
```

3. Install the Python build tools into the venv:

```powershell
.\.venv\Scripts\python.exe -m pip install --upgrade pip fire wheel setuptools
```

`fire` is required for `python -m dev ...`.
`wheel` is required for `bdist_wheel`.

4. Make sure Node.js is available.

5. Enable Corepack so `yarn` is available:

```powershell
corepack enable
```

On recent Node.js releases, `corepack` ships with Node and is the preferred way to provide `yarn`.
If you use `.\build.ps1`, it handles Corepack setup for you automatically with repo-local shims in `.corepack-bin`.

This is required for:

- `yarn install` in `robotframework-ls`
- `python -m dev vendor-robotframework-interactive`

6. Make sure `vsce` is available, or use `npx vsce@2.6.7`.

## Verified Build Steps

### 1. Install extension dependencies

Run from `robotframework-ls`:

```powershell
cd robotframework-ls
corepack enable
yarn install
```

### 2. Refresh generated files

Run from `robotframework-ls`:

```powershell
$env:PYTHONPATH = "src"
& ..\.venv\Scripts\python.exe codegen\codegen_package.py
```

This rewrites generated files such as:

- `robotframework-ls/package.json`
- `robotframework-ls/src/robotframework_ls/commands.py`
- `robotframework-ls/src/robotframework_ls/impl/robot_generated_lsp_constants.py`
- `robotframework-interactive/src/robotframework_interactive/server/rf_interpreter_generated_lsp_constants.py`

### 3. Vendor runtime pieces into `robotframework-ls`

Run from `robotframework-ls`:

```powershell
& ..\.venv\Scripts\python.exe -m dev vendor-robocorp-ls-core
& ..\.venv\Scripts\python.exe -m dev vendor-robotframework-interactive
& ..\.venv\Scripts\python.exe -m dev vendor-robotframework-output-stream
```

Notes:

- `vendor-robotframework-interactive` runs its own `yarn install` inside `robotframework-interactive/vscode-interpreter-webview`.
- `vendor-robotframework-output-stream` installs `robotframework-output-stream` into the vendored target directory by itself.

### 4. Build the Python package

Run from `robotframework-ls/src`:

```powershell
cd src
& ..\..\.venv\Scripts\python.exe setup.py sdist bdist_wheel --universal
```

Output:

- `robotframework-ls/src/dist/robotframework_lsp-<version>.tar.gz`
- `robotframework-ls/src/dist/robotframework_lsp-<version>-py2.py3-none-any.whl`

### 5. Build the VSIX

Go back to `robotframework-ls`:

```powershell
cd ..
vsce package -o robotframework-lsp-<version>.vsix
```

If `vsce` cannot find `yarn`, this also worked:

```powershell
npx --yes vsce@2.6.7 package --no-yarn -o robotframework-lsp-<version>.vsix
```

Output:

- `robotframework-ls/robotframework-lsp-<version>.vsix`

## Not Actually Required For A Local Build

- `python -m dev set-version ...`
  Only needed when you want to change the version before building.

- `cp ../README.md ./README.md`
  Not needed. `robotframework-ls/src/setup.py` already copies `README.md`, `LICENSE`, `COPYRIGHT`, and `ThirdPartyNotices.txt` into place before packaging.

- `twine`
  Not needed just to build the wheel/sdist and VSIX locally.

- `jinja2`
  Not needed by the verified local build flow above.

- `pip install robotframework-output-stream`
  Not needed in the venv for the build flow above. The vendoring step installs it into the vendored target itself.

## Artifacts Verified In This Repo

The build produced:

- `robotframework-ls/src/dist/robotframework_lsp-1.14.0.tar.gz`
- `robotframework-ls/src/dist/robotframework_lsp-1.14.0-py2.py3-none-any.whl`
- `robotframework-ls/robotframework-lsp-1.14.0.vsix`

## Packaging Notes

- `robotframework-ls/LICENSE` is now tracked so `vsce` can include a license file from the extension root.
- `robotframework-ls/.vscodeignore` now excludes repo-local caches, docs, codegen sources, tests, and other build-only files so the VSIX does not pick up unnecessary workspace contents.
