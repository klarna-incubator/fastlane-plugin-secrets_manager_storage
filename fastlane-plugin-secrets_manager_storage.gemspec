lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/secrets_manager_storage/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-secrets_manager_storage'
  spec.version       = Fastlane::SecretsManagerStorage::VERSION
  spec.author        = 'Case Taintor'
  spec.email         = 'case.taintor@klarna.com'

  spec.summary       = 'Enables fastlane match to use AWS Secrets Manager as backing storage'
  spec.homepage      = "https://github.com/klarna-incubator/fastlane-plugin-secrets_manager_storage"
  spec.license       = "Apache-2.0"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version = '>= 2.6'

  spec.add_dependency 'aws-sdk-secretsmanager', '~> 1.0'
end
