require "rails_helper"

RSpec.feature "Mentor receives welcome email", js: true do
  let(:mentor) { FactoryBot.create(:mentor) }

  background do
    Rails.application.configure do
      config.action_mailer.default_url_options = {
        host: Capybara.current_session.server.host,
        port: Capybara.current_session.server.port
      }
    end
  end

  background(:each) do
    clear_emails
    open_email(mentor.email)
  end

  context "already logged in" do
    before do
      sign_in mentor
    end

    scenario "signing the consent waiver" do
      current_email.click_link 'Sign the consent waiver'
      expect(page).to have_content("Technovation Volunteer Agreement")

      fill_in "Type your name", with: "me"
      click_button "I agree"

      expect(page).to have_content("Thank you for signing the consent waiver")
    end
  end

  context "not logged in" do
    scenario "signing the consent waiver" do
      current_email.click_link 'Sign the consent waiver'
      expect(page).to have_content("Technovation Volunteer Agreement")
    end
  end
end