require "rails_helper"

RSpec.describe Team do
  before { Timecop.travel(Division.cutoff_date - 1.day) }
  after { Timecop.return }

  it "knows when it's a past or current team" do
    team = FactoryBot.create(:team)
    expect(team).to be_current
    expect(team).not_to be_past

    team.seasons = [Season.current.year - 1]
    expect(team).not_to be_current
    expect(team).to be_past
  end

  it "deals okay with funky region name input" do
    team = FactoryBot.create(:team)

    allow(team).to receive(:state_province) { " NY " }

    expect { team.region_name }.not_to raise_error
  end

  it "fixes funky brasil/brazil region issue" do
    team = FactoryBot.create(:team)

    allow(team).to receive(:state_province) { "Brasil" }
    expect(team.region_name).to eq("Brazil")

    allow(team).to receive(:state_province) { "Brazil" }
    expect(team.region_name).to eq("Brazil")
  end

  it "assigns to the B division if all students are in Division B" do
    team = FactoryBot.create(:team)
    younger_student = FactoryBot.create(:student, date_of_birth: 13.years.ago)
    older_student = FactoryBot.create(
      :student,
      date_of_birth: Division.cutoff_date - 15.years
    )

    TeamRosterManaging.add(team, [older_student, younger_student])

    expect(team.division).to eq(Division.senior)
  end

  it "assigns to the correct division if a student updates their birthdate" do
    team = FactoryBot.create(:team)
    younger_student = FactoryBot.create(:student, date_of_birth: 13.years.ago)
    older_student = FactoryBot.create(:student, date_of_birth: 14.years.ago)

    TeamRosterManaging.add(team, [older_student, younger_student])

    ProfileUpdating.execute(older_student, {
      account_attributes: {
        id: older_student.account_id,
        date_of_birth: 13.years.ago,
      },
    })

    expect(team.reload.division).to eq(Division.junior)
  end

  it "reconsiders division when a student leaves the team" do
    team = FactoryBot.create(:team)
    younger_student = FactoryBot.create(:student, date_of_birth: 13.years.ago)
    older_student = FactoryBot.create(:student, date_of_birth: 15.years.ago)

    TeamRosterManaging.add(team, [older_student, younger_student])
    expect(team.reload.division).to eq(Division.senior)

    TeamRosterManaging.remove(team, older_student)
    expect(team.reload.division).to eq(Division.junior)
  end

  it "scopes to past seasons" do
    FactoryBot.create(:team) # current season by default

    past_date = if Season.switch_date.year === Time.current.year
                  Season.switch_date - 367.days
                else
                  Season.switch_date - 1.day
                end

    past_team = FactoryBot.create(:team, created_at: past_date)

    expect(Team.past).to eq([past_team])
  end

  it "scopes to the current season" do
    current_team = FactoryBot.create(:team) # current season by default

    past_date = if Season.switch_date.year === Time.current.year
                  Season.switch_date - 367.days
                else
                  Season.switch_date - 1.day
                end

    FactoryBot.create(:team, created_at: past_date)
    expect(Team.current).to eq([current_team])
  end

  it "excludes current season teams from the past scope" do
    current_team = FactoryBot.create(:team) # current season by default

    past_date = if Season.switch_date.year === Time.current.year
                  Season.switch_date - 367.days
                else
                  Season.switch_date - 1.day
                end

    past_team = FactoryBot.create(:team, created_at: past_date)

    current_team.update(seasons: (current_team.seasons << past_team.seasons.last))

    expect(Team.past).not_to include(current_team)
  end

  it "registers to past seasons" do
    team = FactoryBot.create(
      :team,
      created_at: Time.new(
        2015,
        Season.switch_month,
        Season.switch_day,
        0,
        0,
        0,
        "-08:00"
      )
    )
    expect(team.reload.seasons).to eq([2016])
  end

  describe ".region_division_name" do
    it "includes state in US" do
      team = FactoryBot.create(:team)
      expect(team.region_division_name).to eq("US_IL,junior")
    end

    it "uses only country outside the US" do
      team = FactoryBot.create(:team,
                                city: "Salvador",
                                state_province: "Bahia",
                                country: "BR")
      expect(team.region_division_name).to eq("BR,junior")
    end

    it "won't blow up without country" do
      team = FactoryBot.create(
        :team,
        city: nil,
        state_province: nil,
        country: nil
      )
      expect(team.region_division_name).to eq(",junior")
    end

    it "should re-cache if member details change" do
      team = FactoryBot.create(:team)
      expect(team.region_division_name).to eq("US_IL,junior")

      member = team.members.sample
      profile_updating = ProfileUpdating.new(member)
      profile_updating.update({
        account_attributes: {
          id: member.account_id,
          date_of_birth: Date.today - 15.years,
        },
      })

      expect(team.reload.region_division_name).to eq("US_IL,senior")
    end

    it "should re-cache if membership changes" do
      team = FactoryBot.create(:team)
      expect(team.region_division_name).to eq("US_IL,junior")

      team.memberships.each(&:destroy)
      expect(team.reload.region_division_name).to eq("US_IL,none_assigned_yet")
    end
  end

  it "geocodes when address info changes" do
    team = FactoryBot.create(:team, :geocoded) # Chicago by default

    # Sanity
    expect(team.latitude).to eq(41.50196838)
    expect(team.longitude).to eq(-87.64051818)

    TeamUpdating.execute(team, {
      city: "Los Angeles",
      state_province: "CA",
    })

    team.reload
    expect(team.latitude).to eq(34.052363)
    expect(team.longitude).to eq(-118.256551)
  end

  it "reverse geocodes when coords change" do
    team = FactoryBot.create(
      :team,
      :geocoded,
      city: "Los Angeles",
      state_province: "CA"
    )

    # Sanity
    expect(team.city).to eq("Los Angeles")
    expect(team.state_province).to eq("CA")
    expect(team.latitude).to eq(34.052363)
    expect(team.longitude).to eq(-118.256551)

    TeamUpdating.execute(team, {
      latitude: 41.50196838,
      longitude: -87.64051818,
    })

    team.reload
    expect(team.city).to eq("Chicago")
    expect(team.state_province).to eq("IL")
  end

  it "removes associated RPEs when address info changes" do
    team = FactoryBot.create(:team)
    rpe = FactoryBot.create(:rpe)

    # Sanity
    team.regional_pitch_events << rpe
    expect(team.reload.selected_regional_pitch_event).to eq(rpe)

    TeamUpdating.execute(team, {
      city: "Los Angeles",
      state_province: "CA",
    })

    team.reload
    expect(team.regional_pitch_events).to be_empty

    # Sanity
    team.regional_pitch_events << rpe
    expect(team.reload.selected_regional_pitch_event).to eq(rpe)

    TeamUpdating.execute(team, {
      city: "Salvador",
      state_province: "Bahia",
      country: "BR",
    })

    team.reload
    expect(team.regional_pitch_events).to be_empty
  end

  it "touches its submission when division changes" do
    team = FactoryBot.create(:team)
    submission = FactoryBot.create(:submission, team: team)
    team.reload

    old_student = FactoryBot.create(:student, date_of_birth: 15.years.ago)
    young_student = FactoryBot.create(:student, date_of_birth: 14.years.ago)

    TeamRosterManaging.add(team, [old_student, young_student])
    expect(team.reload).to be_senior

    submission_updated = submission.updated_at

    TeamRosterManaging.remove(team, old_student)
    expect(team.reload).to be_junior

    expect(submission_updated).to be < submission.reload.updated_at
  end

  context "unique name validation" do
    it "ensures uniqueness within season" do
      fring = FactoryBot.create(:team, name: "Say My Name")
      heisenberg = FactoryBot.build(:team, name: "Say My Name")
      expect(heisenberg).not_to be_valid
      expect(heisenberg.save).to be false
    end

    it "ensures uniqueness across seasons" do
      fring = FactoryBot.create(:team, name: "Say My Name")
      fring.update(seasons: [Season.current.year - 1])

      heisenberg = FactoryBot.build(:team, name: "Say My Name")
      expect(heisenberg).not_to be_valid
      expect(heisenberg.save).to be false
    end

    it "allows reuse of deleted team names" do
      fring = FactoryBot.create(:team, name: "Say My Name")
      fring.destroy

      heisenberg = FactoryBot.create(:team, name: "Say My Name")
      expect(heisenberg).to be_valid
      expect(heisenberg.reload.id).not_to be_nil
    end

    it "allows exceptions for past names" do
      past_team = FactoryBot.create(:team, name: "Old Name")
      past_team.update(seasons: [Season.current.year - 1])

      new_team = FactoryBot.build(:team, name: "Old Name")
      new_team.name_uniqueness_exceptions = ["Old Name", "Something Else"]

      expect(new_team).to be_valid
      expect(new_team.save).to be true
    end

    it "doesn't allow exceptions for current names" do
      team1 = FactoryBot.create(:team, name: "Team Name")
      team2 = FactoryBot.build(:team, name: "Team Name")
      team2.name_uniqueness_exceptions = ["Team Name"]

      expect(team2).not_to be_valid
      expect(team2.save).to be false
    end
  end

  it "deletes itself, pending requests/invites when membership decrements to zero" do
    team = FactoryBot.create(:team)

    team.team_member_invites.create!(
      invitee_email: "will@delete.com",
      inviter: FactoryBot.create(:mentor),
    )

    team.join_requests.create!(
      requestor: FactoryBot.create(:student),
    )

    team.members.each do |m|
      TeamRosterManaging.remove(team, m)
    end

    expect(team).to be_deleted
    expect(team.team_member_invites).to be_empty
    expect(team.join_requests).to be_empty
  end

  describe ".unmatched(scope)" do
    it "lists teams without a mentor" do
      mentored = FactoryBot.create(:team)
      mentor = FactoryBot.create(:mentor)
      TeamRosterManaging.add(mentored, mentor)

      expect {
        FactoryBot.create(:team)
      }.to change {
        Team.unmatched(:mentor).count
      }.from(0).to(1)
    end

    it "lists teams without students" do
      FactoryBot.create(:team)

      unmatched = FactoryBot.create(:team)
      mentor = FactoryBot.create(:mentor)
      TeamRosterManaging.add(unmatched, mentor)

      expect {
        unmatched.students.each do |student|
          TeamRosterManaging.remove(unmatched, student)
        end
      }.to change {
        Team.unmatched(:students).count
      }.from(0).to(1)
    end
  end

  describe ".matched(scope)" do
    it "lists teams with a mentor" do
      FactoryBot.create(:team)

      mentored = FactoryBot.create(:team)
      mentor = FactoryBot.create(:mentor)

      expect {
        TeamRosterManaging.add(mentored, mentor)
      }.to change {
        Team.matched(:mentor).count
      }.from(0).to(1)
    end

    it "lists teams with students" do
      matched = FactoryBot.create(:team)
      student = matched.students.first

      TeamRosterManaging.remove(matched, student)
      matched.update_column(:deleted_at, nil)
      matched.reload

      expect {
        TeamRosterManaging.add(matched, student)
      }.to change {
        Team.matched(:students).count
      }.from(0).to(1)
    end

    it "counts correctly when both are requested" do
      FactoryBot.create(:team) # only has students

      matched = FactoryBot.create(:team)
      matched.memberships.destroy_all
      mentor = FactoryBot.create(:mentor)

      expect {
        TeamRosterManaging.add(matched, mentor)
      }.to change {
        Team.matched(:students).matched(:mentor).count
      }.from(0).to(1)
    end
  end

  describe ".in_region" do
    it "scopes to the given US ambassador's state" do
      FactoryBot.create(
        :team,
        city: "Los Angeles",
        state_province: "CA",
        country: "US"
      )

      il_team = FactoryBot.create(:team)
      il_ambassador = FactoryBot.create(:ambassador)

      expect(
        Team.in_region(il_ambassador)
      ).to eq([il_team])
    end

    it "scopes to the given Int'l ambassador's country" do
      FactoryBot.create(:team)

      intl_team = FactoryBot.create(
        :team,
        city: "Salvador",
        state_province: "Bahia",
        country: "Brazil"
      )

      intl_ambassador = FactoryBot.create(
        :ambassador,
        city: "Salvador",
        state_province: "Bahia",
        country: "Brazil"
      )

      expect(
        Team.in_region(intl_ambassador)
      ).to eq([intl_team])
    end
  end

  it "keeps track of having students and mentors" do
    team = FactoryBot.create(:team) # student by default in factory
    expect(team).to be_has_students

    mentor = FactoryBot.create(:mentor)
    TeamRosterManaging.add(team, mentor)
    expect(team).to be_has_mentor

    team.students.each do |s|
      TeamRosterManaging.remove(team, s)
    end
    expect(team.reload).not_to be_has_students

    team.mentors.each do |m|
      TeamRosterManaging.remove(team, m)
    end
    expect(team.reload).not_to be_has_mentor
  end
end
