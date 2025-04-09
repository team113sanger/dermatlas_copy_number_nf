# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] - 2024-04-09
## Added 
- Updated CI version
- Readme and documentation improvements
### Fixed
- Pipeline-bundled data sanisitised and sanity-checked for publication 


## [0.6.0] - 2024-03-03
### Fixed
- Corrected a bug in the processing of metadata files that cause the pipeline to skip instances of multiple samples from the same patient.

## [0.6.1] - 2024-03-28
### Added
- Added ASCAT raw_segments file to published results.

## [0.6.0] - 2024-03-03
### Fixed
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
- Changed structure to support seperate one-tumor-per-patient and independent tumor runs within the same pipeline run
- Changed output file directories to mirror exisiting Dermatlas pipeline structure.s

### Added 
- Gistic2 broad-peak filtering support
- Creation of some missing files from existing copy-number process.

## [0.1.1] - 2024-06-03
### Changed
- Using tagged images for Gistic + Gistic Assess (0.5.0). Changed to suppport 
cli based summarise estimates

## [0.1.0] - 2024-06-03
- Initial release of the dermatlas copy number pipeline for user-testing
