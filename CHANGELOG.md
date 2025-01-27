# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2024-01-27

### Fixed

- Fixed issue where certificate upload would fail due to naming constraints in Secrets Manager (#5). Thanks to @magneticrob

## [1.1.0] - 2024-02-13

### Changed

- Distribution and Mobile Provisioning certificates will now have tags on their Secret taken from
  the certificate metadata, enabling faster identification of certificate and tracking of
  expiration.

## [1.0.0] - 2024-02-12

### Added

- Fastlane can now use AWS Secrets Manager as as storage backend

[1.1.0]: https://github.com/klarna-incubator/TODO/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/klarna-incubator/TODO/releases/tag/v1.0.0
