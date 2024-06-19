# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
