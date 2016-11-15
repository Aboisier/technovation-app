module RegionalAccount
  def self.call(ambassador, params = {})
    account = if params[:type] == "All"
                Account
              else
                Account.joins("#{params[:type].underscore}_profile".to_sym)
              end

    accounts = account.includes(:seasons)
      .references(:seasons)
      .where("seasons.year = ?", params[:season])
      .where.not(email: "info@technovationchallenge.org")

    unless params[:text].blank?
      results = accounts.search(
        query: {
          query_string: {
            query: "*#{params[:text]}*"
          }
        },
        from: 0,
        size: 10_000,
      ).results

      accounts = accounts.where(id: results.flat_map { |r| r._source.id })
    end

    if params[:type] == "Student"
      accounts = case params[:parental_consent_status]
                 when "Signed"
                   accounts.joins(student_profile: :parental_consent)
                 when "Sent"
                   accounts.includes(student_profile: :parental_consent)
                     .references(:parental_consents)
                     .where("parental_consents.id IS NULL AND student_profiles.parent_guardian_email IS NOT NULL")
                 when "No Info Entered"
                   accounts.where("student_profiles.parent_guardian_email IS NULL")
                 else
                   accounts
                 end
    end

    if params[:type] == "Mentor"
      case params[:team_status]
      when "On a team"
        accounts = accounts.where("mentor_profiles.id IN
            (SELECT DISTINCT(member_id) FROM memberships
                                        WHERE memberships.member_type = 'MentorProfile'
                                        AND memberships.joinable_type = 'Team'
                                        AND memberships.joinable_id IN

              (SELECT DISTINCT(id) FROM teams WHERE teams.id IN

                (SELECT DISTINCT(registerable_id) FROM season_registrations
                                                  WHERE season_registrations.registerable_type = 'Team'
                                                  AND season_registrations.season_id = ?)))", Season.current.id)
      when "No team"
        accounts = accounts.where("mentor_profiles.id NOT IN
            (SELECT DISTINCT(member_id) FROM memberships
                                        WHERE memberships.member_type = 'MentorProfile'
                                        AND memberships.joinable_type = 'Team'
                                        AND memberships.joinable_id IN

              (SELECT DISTINCT(id) FROM teams WHERE teams.id IN

                (SELECT DISTINCT(registerable_id) FROM season_registrations
                                                  WHERE season_registrations.registerable_type = 'Team'
                                                  AND season_registrations.season_id = ?)))", Season.current.id)
      end
    end

    accounts = accounts
      .includes(:regional_ambassador_profile)
      .references(:regional_ambassador_profiles)
      .where("regional_ambassador_profiles.id IS NULL OR
                regional_ambassador_profiles.status = ?",
             RegionalAmbassadorProfile.statuses[:approved])

    if ambassador.country == "US"
      accounts.where(state_province: ambassador.state_province)
    else
      accounts.where(country: ambassador.country)
    end
  end
end
