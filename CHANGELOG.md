# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).



## [Unreleased]

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
