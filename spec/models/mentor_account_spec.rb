require "rails_helper"

RSpec.describe MentorProfile do
  describe "#team_region_division_names" do
    it "should include all teams" do
      mentor = FactoryBot.create(:mentor)
      t1 = FactoryBot.create(:team,
                              city: "Los Angeles",
                              state_province: "CA",
                              division: Division.senior)
      TeamRosterManaging.add(t1, mentor)

      t2 = FactoryBot.create(:team, division: Division.junior)
      TeamRosterManaging.add(t2, mentor)

      expect(mentor.team_region_division_names).to match_array([
        "US_CA,senior",
        "US_IL,junior"
      ])
    end

    it "should not contain duplicates" do
      mentor = FactoryBot.create(:mentor)
      t1 = FactoryBot.create(:team,
                              city: "Los Angeles",
                              state_province: "CA",
                              division: Division.senior)
      TeamRosterManaging.add(t1, mentor)

      t2 = FactoryBot.create(:team,
                              city: "Los Angeles",
                              state_province: "CA",
                              division: Division.senior)
      TeamRosterManaging.add(t2, mentor)

      expect(mentor.team_region_division_names).to match_array(["US_CA,senior"])
    end
  end

  it "changes searchability when country changes" do
    mentor = FactoryBot.create(:mentor) # Default in US

    # Sanity
    mentor.background_check.destroy
    expect(mentor).not_to be_searchable

    mentor.country = "BR"
    mentor.valid?
    expect(mentor).to be_searchable
  end
end
