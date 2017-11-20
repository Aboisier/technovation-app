require "rails_helper"

RSpec.describe Account do
  subject(:account) { FactoryBot.create(:account) }

  it "sets an auth token" do
    expect(account.auth_token).not_to be_blank
  end

  it "returns a NullTeams for accounts that can't be on teams" do
    %w{judge regional_ambassador}.each do |type|
      profile = FactoryBot.create(type)
      expect(profile.account.teams.current).to eq(Team.none)
    end
  end

  it "requires a secure password when invited" do
    FactoryBot.create(:team_member_invite, invitee_email: "test@account.com")
    account = FactoryBot.build(
      :account,
      email: "test@account.com",
      password: "short"
    )
    expect(account).not_to be_valid
    expect(account.errors[:password]).to eq([
      "is too short (minimum is 8 characters)"
    ])
  end

  %i{mentor regional_ambassador}.each do |type|
    it "doesn't need a BG check outside of the US" do
      account = FactoryBot.create(type,
                                   city: "Salvador",
                                   state_province: "Bahia",
                                   country: "BR")
      expect(account).to be_background_check_complete
    end
  end

  it "calculates age" do
    account.date_of_birth = 15.years.ago + 1.day
    expect(account.age).to eq(14)

    account.date_of_birth = 15.years.ago
    expect(account.age).to eq(15)
  end

  it "calculates age compared to a particular date" do
    account.date_of_birth = 15.years.ago + 3.months
    expect(account.age(3.months.from_now)).to eq(15)
  end

  it "does a somewhat normal email validation" do
    account.skip_existing_password = true

    account.email = "hello@world.com"
    account.valid?
    expect(account.errors.keys).not_to include(:email)

    account.email = "hellono"
    account.valid?
    expect(account.errors.keys).to include(:email)

    account.email = "hello@world.com, hello@someone.com"
    account.valid?
    expect(account.errors.keys).to include(:email)
  end

  it "does not require a password for email case changing" do
    account = FactoryBot.build(:account, email: "caSE@change.COM")
    account.save(validate: false)

    account.reload

    expect(account.save).to be true
    expect(account.reload.email).to eq("case@change.com")
  end

  it "re-cache team_region_division_names as account gets added to new teams" do
    account = FactoryBot.create(:mentor).account
    expect(account.team_region_division_names).to be_empty

    account.teams << FactoryBot.create(:team)
    expect(account.team_region_division_names).to match_array(["US_IL,junior"])

    account.teams << FactoryBot.create(
      :team,
      city: "Los Angeles",
      state_province: "CA"
    )
    expect(account.team_region_division_names).to match_array(
      ["US_IL,junior",
       "US_CA,junior"]
    )
  end

  describe ".inactive_mentors" do
    it "pulls mentors with no new activities since 3 weeks ago" do
      active = FactoryBot.create(:mentor)
      inactive = FactoryBot.create(:mentor)

      active.activities.destroy_all
      inactive.activities.destroy_all

      active.account.create_activity({
        key: "account.update"
      })

      inactive.account.create_activity({
        key: "account.update",
        created_at: 22.days.ago
      })

      expect(Account.inactive_mentors).to eq([inactive.account])
    end
  end

  describe ".matched" do
    it "returns students with current teams" do
      judge = FactoryBot.create(:judge)
      unmatched_student = FactoryBot.create(:student)

      past_student = FactoryBot.create(:student, :on_team)
      past_student.team.update_column(:seasons, [Season.current.year - 1])

      matched_student = FactoryBot.create(:student, :on_team)

      expect(Account.matched).to include(matched_student.account)

      expect(Account.matched).not_to include(judge.account)
      expect(Account.matched).not_to include(past_student.account)
      expect(Account.matched).not_to include(unmatched_student.account)
    end

    it "includes mentors with current teams" do
      unmatched_mentor = FactoryBot.create(:mentor)
      matched_mentor = FactoryBot.create(:mentor, :on_team)

      past_mentor = FactoryBot.create(:mentor, :on_team)

      past_mentor.teams.each do |team|
        team.update_column(:seasons, [Season.current.year - 1])
      end

      expect(Account.matched).to include(matched_mentor.account)

      expect(Account.matched).not_to include(unmatched_mentor.account)
      expect(Account.matched).not_to include(past_mentor.account)
    end
  end

  describe ".unmatched" do
    it "returns students without current teams" do
      judge = FactoryBot.create(:judge)
      unmatched_student = FactoryBot.create(:student)

      past_student = FactoryBot.create(:student, :on_team)
      past_student.team.update_column(:seasons, [Season.current.year - 1])

      matched_student = FactoryBot.create(:student, :on_team)

      expect(Account.unmatched).to include(past_student.account)
      expect(Account.unmatched).to include(unmatched_student.account)

      expect(Account.unmatched).not_to include(matched_student.account)
      expect(Account.unmatched).not_to include(judge.account)
    end

    it "includes mentors without current teams" do
      unmatched_mentor = FactoryBot.create(:mentor)
      matched_mentor = FactoryBot.create(:mentor, :on_team)

      past_mentor = FactoryBot.create(:mentor, :on_team)

      past_mentor.teams.each do |team|
        team.update_column(:seasons, [Season.current.year - 1])
      end

      expect(Account.unmatched).to include(unmatched_mentor.account)
      expect(Account.unmatched).to include(past_mentor.account)

      expect(Account.unmatched).not_to include(matched_mentor.account)
    end
  end

  describe ".parental_consented" do
    it "returns students with current signed parental consents" do
      judge = FactoryBot.create(:judge)
      mentor = FactoryBot.create(:mentor)
      ra = FactoryBot.create(:ambassador)

      unconsented_student = FactoryBot.create(:onboarding_student)

      past_consented_student = FactoryBot.create(:onboarded_student)
      past_consented_student.account.update(
        seasons: [Season.current.year - 1]
      )
      past_consented_student.parental_consent.update(
        seasons: [Season.current.year - 1]
      )

      consented_student = FactoryBot.create(:onboarded_student)

      expect(Account.parental_consented).to include(consented_student.account)

      expect(Account.parental_consented).not_to include(judge.account)
      expect(Account.parental_consented).not_to include(mentor.account)
      expect(Account.parental_consented).not_to include(ra.account)

      expect(Account.parental_consented).not_to include(past_consented_student.account)
      expect(Account.parental_consented).not_to include(unconsented_student.account)
    end

    it "returns students by season with signed parental consents" do
      judge = FactoryBot.create(:judge)
      mentor = FactoryBot.create(:mentor)
      ra = FactoryBot.create(:ambassador)

      unconsented_student = FactoryBot.create(:onboarding_student)

      past_consented_student = FactoryBot.create(:onboarded_student)
      past_consented_student.account.update(
        seasons: [Season.current.year - 1]
      )
      past_consented_student.parental_consent.update(
        seasons: [Season.current.year - 1]
      )

      past_unconsented_student = FactoryBot.create(:onboarded_student)
      past_unconsented_student.account.update(
        seasons: [Season.current.year - 1]
      )
      past_unconsented_student.parental_consent.update(
        seasons: [Season.current.year - 1],
        status: :pending
      )

      consented_student = FactoryBot.create(:onboarded_student)

      results = Account.parental_consented(Season.current.year - 1)

      expect(results).to include(past_consented_student.account)

      expect(results).not_to include(judge.account)
      expect(results).not_to include(mentor.account)
      expect(results).not_to include(ra.account)

      expect(results).not_to include(consented_student.account)
      expect(results).not_to include(unconsented_student.account)
      expect(results).not_to include(past_unconsented_student.account)
    end
  end

  describe ".not_parental_consented" do
    it "returns current students without signed parental consents" do
      judge = FactoryBot.create(:judge)
      mentor = FactoryBot.create(:mentor)
      ra = FactoryBot.create(:ambassador)

      unconsented_student = FactoryBot.create(:onboarding_student)

      past_consented_student = FactoryBot.create(:onboarded_student)
      past_consented_student.account.update(
        seasons: [Season.current.year - 1]
      )
      past_consented_student.parental_consent.update(
        seasons: [Season.current.year - 1]
      )

      past_unconsented_student = FactoryBot.create(:onboarding_student)
      past_unconsented_student.account.update(
        seasons: [Season.current.year - 1]
      )

      consented_student = FactoryBot.create(:onboarded_student)

      results = Account.not_parental_consented
      expect(results).to include(unconsented_student.account)

      expect(results).not_to include(judge.account)
      expect(results).not_to include(mentor.account)
      expect(results).not_to include(ra.account)

      expect(results).not_to include(consented_student.account)
      expect(results).not_to include(past_consented_student.account)
      expect(results.current).not_to include(past_unconsented_student.account)
    end

    it "returns students by season without signed parental consents" do
      judge = FactoryBot.create(:judge)
      mentor = FactoryBot.create(:mentor)
      ra = FactoryBot.create(:ambassador)

      unconsented_student = FactoryBot.create(:onboarding_student)

      past_consented_student = FactoryBot.create(:onboarded_student)
      past_consented_student.account.update(
        seasons: [Season.current.year - 1]
      )
      past_consented_student.parental_consent.update(
        seasons: [Season.current.year - 1]
      )

      past_unconsented_student = FactoryBot.create(:onboarded_student)
      past_unconsented_student.account.update(
        seasons: [Season.current.year - 1]
      )
      past_unconsented_student.parental_consent.update(
        seasons: [Season.current.year - 1],
        status: :pending
      )

      consented_student = FactoryBot.create(:onboarded_student)

      results = Account.not_parental_consented(Season.current.year - 1)

      expect(results).to include(past_unconsented_student.account)

      expect(results).not_to include(judge.account)
      expect(results).not_to include(mentor.account)
      expect(results).not_to include(ra.account)

      expect(results).not_to include(past_consented_student.account)
      expect(results).not_to include(unconsented_student.account)
    end
  end
end
