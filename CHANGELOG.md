# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Keywords

As of the release following 1.1.1 the following *keywords* are used at the start of each
changelog entry to indicate the impact of the change:

- **REPRODUCIBILITY** - a change to the pipeline's scientific processing that
  may cause the same input data to produce different scientific outputs or
  results, including changes to algorithms, tolerances, randomisation,
  scientific functionality, or output formats.
- **ROBUSTNESS** - a fix or improvement to the pipeline's scientific
  functionality that improves correctness, reliability, or the range of inputs
  that can be processed, without intentionally changing the scientific results
  of an equivalent successful analysis.
- **INTEGRATION** - a change to how the pipeline integrates with other systems
  or infrastructure, without changing its scientific processing or results.

## [Unreleased]
### Added
- **INTEGRATION** - run reporting. `lib/Utils.groovy` (shared verbatim with the other
  Dermatlas pipelines) is wired in by `workflow.onComplete { Utils.reportRun(workflow, params) }`
  and records each run in the Dermatlas website's analysis log (via `dermatlas-http`, >= 0.6.1)
  and/or posts a Slack message. Both are explicit opt-ins, gated by the
  `DERMATLAS_WEBSITE_LOGGING` / `DERMATLAS_SLACK_NOTIFICATIONS` environment toggles, and
  never fire on stub runs. `nextflow.config` gains `is_stub`,
  `analysis_pipeline_slug = 'copynumber_pipe'` and `trace_file`.
- **INTEGRATION** - `nextflow.config` gains a `trace {}` block. The execution trace and
  report are named `execution_trace-<RUN_ID>.txt` / `execution_report-<RUN_ID>.html`
  under the launcher's `TRACE_DIR`, from the `RUN_ID` the launcher exports (a bare
  timestamp for a direct `nextflow run`).
- **INTEGRATION** - `assets/run_copy_number.sh` is rebuilt from the reference Dermatlas
  launcher (`dermatlas_rnafusions_nf`): it sources the project `source_me.sh`
  (`SOURCE_ME`, `"none"` to skip), validates the environment before launch, reports a
  failed launch to stderr and (opt-in) Slack, holds an exclusive `flock` on
  `${PROJECT_DIR}/copynumber_pipe/.lock` (a concurrent submission exits 75), writes a
  `.completed_successfully` / `.completed_with_error` sentinel, one log per nextflow
  command (`logs/nextflow-{pull,run}-<RUN_ID>.log`), per-revision `NXF_ASSETS` clones, a
  pinned `NXF_SINGULARITY_CACHEDIR`, and on success writes
  `stats/resource-stats-<RUN_ID>.txt`, reports the work-dir usage to the website
  (`dermatlas-http cohort analysis-workdir-stats`, >= 0.6.2, module-loaded via
  `DERMATLAS_HTTP_MODULE`) and deletes the work directory (`DERMATLAS_CLEANUP_WORK_DIR`).
  See "Without the website", "Toggles" and "Reclaiming disk space" in the README.
- **INTEGRATION** - `.update-version.sh` sets the release version in every file that
  records it; "Cutting a release" in the README now uses it.
- **REPRODUCIBILITY** - a third subcohort, `related_tumours`, is analysed from the
  pairs in `DNA_PAIR_LIST_RELATED_TUMOURS_MATCHED` (plots under `PLOTS_RELATED`). A cohort
  whose list is empty, or whose related pairs all fail the ASCAT goodness-of-fit filter,
  produces no `related_tumours` outputs and no error.
- **INTEGRATION** - `copy_number.config` feeds the `related_tumours` subcohort from
  `DNA_PAIR_LIST_RELATED_TUMOURS_MATCHED`, which `run_copy_number.sh` now checks is
  exported; the MANUAL ENVIRONMENT OVERRIDES block and the README's standalone contract
  list it too (twelve exports).

### Changed
- **INTEGRATION** - **Breaking:** the launcher no longer reads its environment from the
  submitting shell; it sources `./source_me.sh` from the submission directory and fails
  at launch, naming the variables, unless it exports `PROJECT_DIR COMMANDS_DIR ANALYSIS_DIR
  BAMS_DIR STUDY PROJECT COHORT DNA_PAIR_LIST_ANALYSED_MATCHED
  DNA_PAIR_LIST_INDEPENDENT_TUMOURS_MATCHED DNA_PAIR_LIST_ONE_TUMOUR_PER_PATIENT_MATCHED
  COHORT_METADATA_FILE` (plus the website/Slack variables when those toggles are on).
  `COHORT_METADATA_FILE` replaces `METADATA_FILE` and is a full path; the generator that
  writes `source_me.sh` has to emit it before a project can run this release.
- **INTEGRATION** - **Breaking:** `assets/copy_number.config` takes its sample lists from
  the variables dermanager exports for them (`DNA_PAIR_LIST_*_MATCHED`) instead of
  rebuilding their paths from a filename convention, `metadata_manifest` from
  `${COHORT_METADATA_FILE}`, `bam_files` from `${BAMS_DIR}` and `outdir` from
  `${ANALYSIS_DIR}`. Outputs land in the same place for a dermanager project.
- **INTEGRATION** - **Breaking:** the launcher's directory moves from
  `${PROJECT_DIR}/copy_number_pipeline` to `${PROJECT_DIR}/copynumber_pipe`, and its
  config from `commands/copy_number.config` to `commands/copynumber_pipe/copy_number.config`,
  matching the slug dermanager unpacks the asset bundle under. A run started under the
  old directory cannot `-resume` in the new one.
- **INTEGRATION** - `.github/workflows/publish-assets.yml` no longer moves the rolling
  `main-latest` / `develop-latest` tags: each is created once and only its bundle is
  replaced, so `git hf release finish` no longer fails on a moved tag.
- **INTEGRATION** - the repository is GitHub-primary: `manifest.homePage`, the README,
  the docs and the workflow header no longer point at or defer to GitLab, and the
  GitLab pipeline badges are gone. The GitLab container registry is unchanged.

### Fixed
- **ROBUSTNESS** - `CREATE_FREQUENCY_PLOTS` receives each subcohort's segments, purity/ploidy
  table and sample-sex file joined on the subcohort name. They were three separate channels
  paired by arrival order, so with more than one subcohort a plot could be built from one
  subcohort's segments and another's purity or sex file. `SUMMARISE_ASCAT_ESTIMATES` now
  emits `purity` with its `meta`. Results are unchanged for any run whose inputs happened
  to arrive in matching order.

### Removed
- **INTEGRATION** - the stray top-level `tracedir = "pipeline_info"` and the
  timestamp-only report name in `nextflow.config`.
- **INTEGRATION** - the stale launcher and config copies embedded in the docs, which now
  link to `assets/`.

## [1.1.1] - 2026-08-27
### Added
- `.github/workflows/publish-assets.yml` publishes `assets/` to GitHub Releases as
  `projectify_asset_bundle.tar.gz` (and a `.sha256` of it) on every push to `main` and
  `develop` - as the rolling `main-latest` and `develop-latest` pre-releases - and on
  every `X.Y.Z` tag. `dermanager projectify` fetches assets from those release URLs
  instead of the GitHub API, which needs no token and is not rate limited. See
  "Asset release bundles" in the README.

## [1.1.0] - 2026-03-12
### Improvements
- Updated Gistic assess steps to use later versions with oncogene annotation
### Fixed
- Fixed minor trace bug on `analyse_subcohort` that caused the pipeline to error out when trying to generate the `samples2sex` file for cohorts 
- Bugfix for skipping analysis of samples with unknown sex.
- Fixing a regression in definition of segments files to use in Gistic

## [1.0.0] - 2026-01-02
### Improvements 
- Switch to sphinx based documentation
- Made Gistic filtering thresholds configurable 
- Substantial architecture and inputs re-work to handle an arbitrary set of sub-cohorts rather than opinionated `oppt` and `independent` cohorts. Now simplified to use a map.
- Removal of opinionated column names from metadata manifest. Configurable with config variables
- Added minimal pipeline tracking
- Partial migration of test artefacts to S3.
- Catches for samples with no annotated sex. 
- Moving towards strict syntax in pipeline code.


## [0.7.6] - 2025-10-06
### Fixed 
- Publishing of `.scores` files from gistic
- Added asset files for multi-pipeline running


## [0.7.5] - 2025-07-15
### Fixed
- Fixed gistic resource path
### Changed
- Updated ASCAT container with new frequency plot aesthetics 
- Updated gistic container to handle cohorts with no significant results

## [0.7.4] - 2024-04-26
### Fixed 
- Updated singularity cachedir

## [0.7.3] - 2024-04-24
### Fixed 
- Updated config paths to reflect new defaults after lustre recovery

## [0.7.2] - 2024-04-24
### Fixed 
- Fixed threshold from 0.95 to 0.9 in the GISTIC2 step to match the manual process. 

## [0.7.1] - 2024-04-24
### Fixed 
- Recommended running using config rather than params + doc how to use w/ env variables
- Fixed a bug in the publishing of collected files that seems to have been introduced in the last release.

## [0.7.0] - 2024-04-09
### Added 
- Updated CI version
- Readme and documentation improvements
### Fixed
- Pipeline-bundled data sanitised and sanity-checked for publication 


## [0.6.1] - 2024-03-28
### Added
- Added ASCAT raw_segments file to published results.

## [0.6.0] - 2024-03-03
### Fixed
- Corrected a bug in the processing of metadata files that cause the pipeline to skip instances of multiple samples from the same patient.
- Corrected a bug in the creation of samples2sex files and the penetrance plots that are generated from them.

## [0.5.0] - 2024-02-12
### Added
- CI testing of some steps
- Moved over to an ASCAT container update that allows on and off pipe running 
### Changed
- Publication directories, parameter names to better match other pipelines 


## [0.4.1] - 2024-09-05
### Added
- Handling of different Dermatlas manifest generations, fixing container version for broad step

## [0.4.0] - 2024-07-27
### Added
- Made independent/one patient per tumor cohort analyses optional
### Changed
- Clearer naming of cohort-level analyses

## [0.3.1] - 2024-07-16
### Changed
- Fix docs for working farm singularity

## [0.3.0] - 2024-06-19
### Changed
- Improved the workflow logic to use filtering joins to subset data for each subgroup


## [0.2.0] - 2024-06-11
### Changed
- Changed structure to support separate one-tumor-per-patient and independent tumor runs within the same pipeline run
- Changed output file directories to mirror existing Dermatlas pipeline structure.

### Added 
- Gistic2 broad-peak filtering support
- Creation of some missing files from existing copy-number process.

## [0.1.1] - 2024-06-03
### Changed
- Using tagged images for Gistic + Gistic Assess (0.5.0). Changed to support 
cli based summarise estimates

## [0.1.0] - 2024-06-03
- Initial release of the dermatlas copy number pipeline for user-testing
