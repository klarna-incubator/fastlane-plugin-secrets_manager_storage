describe Fastlane::Actions::SecretsManagerStorageAction do
  describe "#run" do
    it "prints a message" do
      expect(Fastlane::UI).to receive(:message).with(
        "The secrets_manager_storage plugin is working!",
      )

      Fastlane::Actions::SecretsManagerStorageAction.run(nil)
    end
  end
end
