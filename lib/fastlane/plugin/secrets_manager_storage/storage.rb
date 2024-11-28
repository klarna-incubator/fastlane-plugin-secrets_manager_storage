require "fastlane_core/command_executor"
require "fastlane_core/configuration/configuration"
require "match"
require "fileutils"
require "aws-sdk-secretsmanager"

module Fastlane
  module SecretsManagerStorage
    class Storage < ::Match::Storage::Interface
      attr_reader :path_prefix
      attr_reader :tags
      attr_reader :region
      attr_reader :git_url
      attr_reader :username
      attr_reader :readonly
      attr_reader :team_id
      attr_reader :team_name
      attr_reader :api_key_path
      attr_reader :api_key

      def self.configure(params)
        if params[:git_url].to_s.length > 0
          UI.important("Looks like you still define a `git_url` somewhere, even though")
          UI.important("you use AWS Secrets Manager. You can remove the `git_url`")
          UI.important("from your Matchfile and Fastfile")
          UI.message("The above is just a warning, fastlane will continue as usual now...")
        end

        return(
          self.new(
            path_prefix: params[:secrets_manager_path_prefix],
            tags: params[:secrets_manager_tags],
            region: params[:secrets_manager_region],
            username: params[:username],
            readonly: params[:readonly],
            team_id: params[:team_id],
            team_name: params[:team_name],
            api_key_path: params[:api_key_path],
            api_key: params[:api_key],
          )
        )
      end

      def initialize(
        path_prefix: nil,
        tags: {},
        region: nil,
        username: nil,
        readonly: nil,
        team_id: nil,
        team_name: nil,
        api_key_path: nil,
        api_key: nil
      )
        @path_prefix = path_prefix
        @tags = tags
        @region = region || ENV["AWS_REGION"]
        @username = username
        @readonly = readonly
        @team_id = team_id
        @team_name = team_name
        @api_key_path = api_key_path
        @api_key = api_key

        @client = Aws::SecretsManager::Client.new(region: region)
        UI.message("Initializing match for AWS Secrets Manager at #{@path_prefix} in #{@region}")
      end

      # To make debugging easier, we have a custom exception here
      def prefixed_working_directory
        # We fall back to "*", which means certificates and profiles
        # from all teams that use this bucket would be installed. This is not ideal, but
        # unless the user provides a `team_id`, we can't know which one to use
        # This only happens if `readonly` is activated, and no `team_id` was provided
        @_folder_prefix ||= currently_used_team_id
        if @_folder_prefix.nil?
          # We use a `@_folder_prefix` variable, to keep state between multiple calls of this
          # method, as the value won't change. This way the warning is only printed once
          UI.important(
            "Looks like you run `match` in `readonly` mode, and didn't provide a `team_id`. This will still work, however it is recommended to provide a `team_id` in your Appfile or Matchfile",
          )
          @_folder_prefix = "*"
        end
        return File.join(working_directory, @_folder_prefix)
      end

      def download
        return if @working_directory

        self.working_directory = Dir.mktmpdir

        next_token = nil
        secret_names = []
        with_aws_authentication_error_handling do
          loop do
            resp =
              @client.list_secrets(
                { next_token: next_token, filters: [{ key: "name", values: [@path_prefix] }] },
              )
            resp.secret_list.each { |secret| secret_names << secret.name }
            next_token = resp.next_token
            break if next_token.nil?
          end

          secret_names.each do |name|
            secret = @client.get_secret_value({ secret_id: name })
            filename = File.join(self.working_directory, name.delete_prefix(self.path_prefix))
            FileUtils.mkdir_p(File.dirname(filename))
            IO.binwrite(filename, secret.secret_binary)
          end
        end

        UI.verbose(
          "Successfully downloaded all Secrets from AWS Secrets Manager to #{self.working_directory}",
        )
      end

      def currently_used_team_id
        if self.readonly
          # In readonly mode, we still want to see if the user provided a team_id
          # see `prefixed_working_directory` comments for more details
          return self.team_id
        else
          if self.team_id.to_s.empty?
            UI.user_error!(
              "The `team_id` option is required. fastlane cannot automatically determine portal team id via the App Store Connect API (yet)",
            )
          end

          spaceship =
            ::Match::SpaceshipEnsure.new(self.username, self.team_id, self.team_name, api_token)
          return spaceship.team_id
        end
      end

      def api_token
        api_token =
          Spaceship::ConnectAPI::Token.from(hash: self.api_key, filepath: self.api_key_path)
        api_token ||= Spaceship::ConnectAPI.token
        return api_token
      end

      # Returns a short string describing + identifying the current
      # storage backend. This will be printed when nuking a storage
      def human_readable_description
        "AWS Secrets Manager Storage [#{self.path_prefix}]"
      end

      def upload_files(files_to_upload: [], custom_message: nil)
        # `files_to_upload` is an array of files that need to be uploaded to AWS Secrets Manager
        # Those doesn't mean they're new, it might just be they're changed
        # Either way, we'll upload them using the same technique

        files_to_upload.each do |current_file|
          # Go from
          #   "/var/folders/px/bz2kts9n69g8crgv4jpjh6b40000gn/T/d20181026-96528-1av4gge/profiles/development/Development_me.mobileprovision"
          # to
          #   "profiles/development/Development_me.mobileprovision"
          #

          # We also remove the trailing `/`
          secret_name = current_file.delete_prefix(self.working_directory)
          UI.verbose("Uploading '#{secret_name}' to AWS Secrets Manager...")
          create_or_update_secret(current_file, secret_name)
        end
      end

      def delete_files(files_to_delete: [], custom_message: nil)
        files_to_delete.each do |current_file|
          secret_name = current_file.delete_prefix(self.working_directory + "/")

          delete_secret(secret_name)
        end
      end

      def skip_docs
        true
      end

      def list_files(file_name: "", file_ext: "")
        Dir[File.join(working_directory, self.team_id, "**", file_name, "*.#{file_ext}")]
      end

      def generate_matchfile_content(template: nil)
        # Will implement once I figure out how to have a plugin with `match` commands
        raise "Not Implemented"
      end

      def create_or_update_secret(current_file, secret_name)
        full_secret_path = generate_secret_path(secret_name)
        secret_specific_tags = generate_tags_for_secret(current_file)
        begin
          @client.describe_secret(secret_id: full_secret_path)
          UI.verbose("Secret '#{secret_name}' already exists, updating...")
          @client.put_secret_value(
            secret_id: full_secret_path,
            secret_binary: IO.binread(current_file),
          )
          unless secret_specific_tags.empty?
            @client.tag_resource(
              secret_id: full_secret_path,
              tags: convert_hash_to_array_of_key_values(secret_specific_tags),
            )
          end
        rescue Aws::SecretsManager::Errors::ResourceNotFoundException
          UI.verbose("Secret '#{secret_name}' doesn't exist, creating...")
          @client.create_secret(
            name: full_secret_path,
            secret_binary: File.open(current_file, "rb").read,
            tags: convert_hash_to_array_of_key_values(tags.merge(secret_specific_tags)),
          )
        end
      end

      def delete_secret(secret_name)
        @client.delete_secret({ secret_id: secret_name, recovery_window_in_days: 7 })
      rescue Aws::SecretsManager::Errors::ResourceNotFoundException
        UI.verbose("Secret '#{secret_name}' doesn't exist, skipping...")
      end

      private

      def generate_tags_for_secret(secret_file)
        return {} unless File.file?(secret_file)

        expiry = nil
        secret_specific_tags = {}
        case File.extname(secret_file)
        when ".p12"
          # not sure how to get expiry of the cert
        when ".cer"
          cert_info = Match::Utils.get_cert_info(secret_file)
          secret_specific_tags["Name"] = cert_info
            .find { |attribute| attribute.first == "Common Name" }
            .last
            .gsub(/[^a-zA-Z0-9_ .:\/=+-]/, "")
          expiry = cert_info.find { |attribute| attribute.first == "End Datetime" }.last
        when ".mobileprovision"
          secret_specific_tags[
            "Name"
          ] = `/usr/libexec/PlistBuddy -c 'Print Name' /dev/stdin <<< $(security cms -D -i "#{secret_file}")`.chomp.strip
          secret_specific_tags[
            "AppIDName"
          ] = `/usr/libexec/PlistBuddy -c 'Print AppIDName' /dev/stdin <<< $(security cms -D -i "#{secret_file}")`.chomp.strip
          secret_specific_tags[
            "AppIdentifier"
          ] = `/usr/libexec/PlistBuddy -c 'Print Entitlements:application-identifier' /dev/stdin <<< $(security cms -D -i "#{secret_file}")`.chomp.strip
          expiry =
            DateTime.parse(
              `/usr/libexec/PlistBuddy -c 'Print ExpirationDate' /dev/stdin <<< $(security cms -D -i "#{secret_file}")`.chomp.strip,
            )
        end
        secret_specific_tags["ExpiresOn"] = expiry.strftime("%Y-%m-%dT%H:%M:%SZ") if expiry
        secret_specific_tags
      end

      def generate_secret_path(secret_name)
        prefix = path_prefix
        prefix += "/" unless secret_name.start_with?("/")
        "#{prefix}#{secret_name}"
      end

      def convert_hash_to_array_of_key_values(tags_as_ruby_hash)
        tags_as_ruby_hash.map { |key, value| { key: key, value: value } }
      end

      def with_aws_authentication_error_handling
        explainer =
          "Note: AWS credentials are passed via environment variables. The AWS Ruby SDK documentation explains which environment variables are expected – https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/setup-config.html"
        yield
      rescue Aws::SecretsManager::Errors::ExpiredTokenException,
             Aws::Errors::MissingCredentialsError => e
        UI.error("AWS Secrets Manager authentication error: #{e}.\n\n#{explainer}")
        raise e
      end
    end
  end
end
