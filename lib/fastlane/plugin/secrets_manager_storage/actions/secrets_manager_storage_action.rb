require "fastlane/action"

module Fastlane
  module Actions
    class SecretsManagerStorageAction < Action
      def self.run(params)
        UI.message(
          "If you're running this action, you shouldn't be. This action only exists because Fastlane expects all plugins to have actions. See the README.md for secrets_manager_storage to understand how to set the match storage",
        )
      end

      def self.description
        "This action is not necessary and is unused – see the README for secrets_manager_storage to learn how to use it. Fastlane expects all plugins to have actions."
      end

      def self.authors
        ["Case Taintor"]
      end

      def self.return_value
      end

      def self.available_options
        []
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
