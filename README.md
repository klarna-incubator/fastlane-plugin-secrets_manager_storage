# Secrets Manager Storage

This plugin enables Fastlane users to store their provisioning profiles and certificates securely in
AWS Secrets Manager by adding a `secrets_manager` storage backend to Fastlane match.

[![Build Status][ci-image]][ci-url]
[![License][license-image]][license-url]
[![Developed at Klarna][klarna-image]][klarna-url]
[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-secrets_manager_storage)

Reasons to use this (compared to the git or s3 backend):

- certificates are stored securley (always encrypted) by default
- all access is controlled via AWS IAM and is fine-grained:
  - users can be granted access to review the secret's metadata separate from the ability to read
    the actual, unencrypted values
  - no need to manage a `MATCH_PASSWORD` – just use your existing AWS access controls
- all access to the decrypted secrets is logged into AWS CloudTrail, providing an audit-trail to
  access
- Secret lifecycle can be tracked independently of Fastlane, enabling you to have alerts on secret
  age by using the secret's version metadata (e.g. Created On)

> :information_source: Fastlane plugins are only automatically loaded when using a Fastfile. This means that
> using a Matchfile or `fastlane match` commands will not work with this storage backing. We're happy to
> take contributions but we've always ended up writing Fastlane actions in our projects anyway (not using the `match` commands or `Matchfile`)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with
`fastlane-plugin-secrets_manager_storage`, add it to your project by running:

```bash
fastlane add_plugin secrets_manager_storage
```

You will then need to modify your Fastfile to have actions which use match/sync_code_signing use the
`secrets_manager` storage backend. You can look in [fastlane/Fastfile](fastlane/Fastfile) in this
repository for example use.

## Formatting

This project is formatted using Prettier. Simply run `rake prettier' to format

```
rake prettier
```

## Development setup

```sh
bundle install
yarn install
```

## How to contribute

See our guide on [contributing](.github/CONTRIBUTING.md).

## Release History

See our [changelog](CHANGELOG.md).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android
apps. To learn more, check out [fastlane.tools](https://fastlane.tools).

## License

Copyright © 2024 Klarna Bank AB

For license details, see the [LICENSE](LICENSE) file in the root of this project.


<!-- Markdown link & img dfn's -->
[ci-image]: https://img.shields.io/badge/build-passing-brightgreen?style=flat-square
[ci-url]: https://github.com/klarna-incubator/TODO
[license-image]: https://img.shields.io/badge/license-Apache%202-blue?style=flat-square
[license-url]: http://www.apache.org/licenses/LICENSE-2.0
[klarna-image]: https://img.shields.io/badge/%20-Developed%20at%20Klarna-black?style=flat-square&labelColor=ffb3c7&logo=klarna&logoColor=black
[klarna-url]: https://klarna.github.io
