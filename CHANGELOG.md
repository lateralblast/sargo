# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed

- Relicensed under CC BY-NC-SA 4.0 and added a LICENSE file.
- Added `cpanfile`, `CLAUDE.md` and this changelog.

## [0.1.7] - 2026-10-04

### Changed

- The main program is wrapped in `main()` and exits explicitly.
- Removed needless quoting and escaping in file tests and regexes.

## [0.1.6] - 2026-10-04

### Changed

- Column label rewrites are ordered tables (`@header_labels`, `@device_labels`, `@memory_labels`) applied by `apply_labels()` instead of long chains of substitutions.
- The main program runs at the end of the file so the tables are initialised before use.

### Fixed

- Uninitialised value warning when building the disk header in `-D` mode.

## [0.1.5] - 2026-10-04

### Changed

- Usage text and the HTML header and footer use here-documents.
- Chart titles come from the `@chart_titles` table.

## [0.1.4] - 2026-10-04

### Changed

- Output is written through a lexical filehandle with `open_output()` and `close_output()` helpers instead of the bareword `OUTPUT`.

## [0.1.3] - 2026-10-04

### Changed

- Enabled `use warnings` and removed an unused variable.
- Fixed indentation and missing semicolons.

## [0.1.2] - 2026-10-04

### Fixed

- `freemem` is converted to GB with two decimals instead of being rounded to a whole number.
- `freeswap` is converted from 512 byte blocks rather than 8 KB pages in the Google Charts output.

## [0.1.1] - 2026-10-04

### Fixed

- Output files are opened with checked `open()` calls, and writes to an unopened output file are skipped instead of warning.
- The input file is read through a lexical filehandle.
- Usage text and examples use the real script name and correct typos.

### Removed

- The unused `-t` option.

## [0.1.0] - 2026-10-04

### Fixed

- Chart titles default to the output file name when no title matches.

## [0.0.9] - 2026-10-04

### Fixed

- Uninitialised variable warnings (`$output_files`, `$device_header`, `$output`, `$date`).

## [0.0.8] - 2026-10-04

### Fixed

- `[A-z]` character class replaced with `[A-Za-z0-9]`.
- Output file names are tracked in a hash rather than matched as a regex.
- Metric names are quoted before being used in a regex.

## [0.0.7] - 2026-10-04

### Fixed

- mpstat elapsed time uses its own counter and is initialised, so it no longer clashes with the disk stats time.
- Default mpstat date is MM/DD/YYYY, matching the sar header format.

## [0.0.6] - 2026-10-04

### Fixed

- A missing `-i` (without `-S`) now gives a clear error and exits non-zero. A missing input file also exits non-zero.

## [0.0.5] - 2026-10-04

### Fixed

- Removal of previous output no longer shells out to an unquoted `rm`.

## [0.0.4] - 2026-10-04

### Fixed

- Default work directory uses the script's base name rather than `$0`.
- `-w` now also moves the raw data file.

## [0.0.3] - 2026-10-04

### Fixed

- `-S` builds a valid shell loop, creates the work directory first, and reads the file it wrote.
- With `-S` and no `-o`, output goes to the work directory prefixed by the hostname.

## [0.0.2] - 2014-06-17

### Changed

- Updated documentation and license.

## [0.0.1] - 2012-11-13

### Added

- Initial commit to GitHub.
