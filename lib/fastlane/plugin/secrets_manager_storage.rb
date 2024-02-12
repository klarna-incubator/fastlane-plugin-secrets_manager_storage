require "fastlane/plugin/secrets_manager_storage/version"
require_relative "./secrets_manager_storage/storage"

Match::Storage.register_backend(
  type: "secrets_manager",
  storage_class: ::Fastlane::SecretsManagerStorage::Storage,
)
Match::Encryption.register_backend(type: "secrets_manager") { nil }

module Fastlane
  module SecretsManagerStorage
    # Return all .rb files inside the "actions" and "helper" directory
    def self.all_classes
      Dir[File.expand_path("**/{actions}/*.rb", File.dirname(__FILE__))]
    end
  end
end

# By default we want to import all available actions and helpers
# A plugin can contain any number of actions and plugins
Fastlane::SecretsManagerStorage.all_classes.each { |current| require current }

# Unfortunately Fastlane/Match does not actually support adding backends via
# a plugin since it hard-codes the allowed storage modes. This code simply monkey-patches
# Fastlane/Match to respond with all registered storage modes
module Match
  def self.storage_modes
    Storage.backends.keys
  end

  class Setup
    def storage_options
      ::Match::Storage.backends.keys
    end
  end
end

# Similarly, Match doesn't (at time of writing) support adding options, so we will once-again monkey-patch
module AddSecretsManagerOptions
  def available_options
    options = super
    options << FastlaneCore::ConfigItem.new(
      key: :secrets_manager_path_prefix,
      env_name: "MATCH_SECRETS_MANAGER_PATH_PREFIX",
      description: "The prefix to be used for all Secrets Manager Secrets",
      optional: true,
      type: String,
    )
    options << FastlaneCore::ConfigItem.new(
      key: :secrets_manager_tags,
      env_name: "MATCH_SECRETS_MANAGER_TAGS",
      description: "tags which are used when creating a new secret in Secrets Manager",
      optional: true,
      type: Hash,
    )
    options << FastlaneCore::ConfigItem.new(
      key: :secrets_manager_region,
      env_name: "MATCH_SECRETS_MANAGER_REGION",
      description: "The prefix to be used for all Secrets Manager Secrets",
      optional: true,
      type: String,
    )
    options
  end
end
Match::Options.singleton_class.prepend(AddSecretsManagerOptions)
