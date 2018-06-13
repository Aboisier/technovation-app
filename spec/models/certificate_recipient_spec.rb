require "spec_helper"
require "./app/models/certificate_recipient"
require "./app/null_objects/null_team_submission"

RSpec.describe CertificateRecipient do
  describe "#needed_certificate_types" do
    context "a team with no submission" do
      it "needs no certificates" do
        account = double(:Account, id: 1, name: "My full name")
        team = double(:Team, name: "Team name", submission: NullTeamSubmission.new)

        recipient = CertificateRecipient.new(account, team)

        expect(recipient.needed_certificate_types).to be_empty
      end
    end

    context "a team with a participation qualifying submission" do
      it "needs a participation certificate" do
        submission = double(
          :TeamSubmission,
          app_name: "Submission app name",
          :qualifies_for_participation? => true,
          :complete? => false,
          :semifinalist? => false
        )

        account = double(
          :Account,
          id: 1,
          name: "My full name",
          current_participation_certificates: []
        )

        team = double(:Team, name: "Team name", submission: submission)

        recipient = CertificateRecipient.new(account, team)

        expect(recipient.needed_certificate_types).to eq(["participation"])
      end
    end
  end

  describe "#certificate_types" do
    context "a team with no submission" do
      it "gets no certificates" do
        account = double(:Account, id: 1, name: "My full name")
        team = double(:Team, name: "Team name", submission: NullTeamSubmission.new)

        recipient = CertificateRecipient.new(account, team)

        expect(recipient.certificate_types).to be_empty
      end
    end
  end

  describe "#certificates" do
    context "a team with no submission" do
      it "has no certificates" do
        account = double(:Account, id: 1, name: "My full name")
        team = double(:Team, name: "Team name", submission: NullTeamSubmission.new)

        recipient = CertificateRecipient.new(account, team)

        expect(recipient.certificates).to be_empty
      end
    end
  end
end