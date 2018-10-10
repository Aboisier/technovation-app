require "rails_helper"

RSpec.describe "Admins checking on submissions" do
  context "on the admin/team pages" do
    it "displays a link to their submission" do
      submission = FactoryBot.create(:submission)

      sign_in(:admin)
      click_link "Teams"
      click_link "view"

      expect(page).to have_link(
        submission.app_name,
        href: admin_team_submission_path(submission)
      )
    end

    it "displays the progress of their submission" do
      submission = FactoryBot.create(:submission, :complete)

      sign_in(:admin)
      click_link "Teams"
      click_link "view"

      within('.submission .bar-graph') do
        expect(page).to have_content("100% completed")
      end
    end
  end
end