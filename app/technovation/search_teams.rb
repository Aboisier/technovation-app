require 'will_paginate/array'

module SearchTeams
  def self.call(filter)
    teams = Team.current

    if filter.nearby.present?
      miles = filter.nearby == "anywhere" ? 40_000 : 50
      nearby = filter.nearby == "anywhere" ? filter.user.address_details : filter.nearby

      account_ids = Account.current.near(nearby, miles).select(:id).map(&:id)

      student_profile_ids = StudentProfile.where(account_id: account_ids).pluck(:id)
      mentor_profile_ids = MentorProfile.where(account_id: account_ids).pluck(:id)

      teams = teams.joins(:memberships)
        .where("(memberships.member_id IN (?) AND memberships.member_type = ?)
                OR
                (memberships.member_id IN (?) AND memberships.member_type = ?)",
                student_profile_ids,
                "StudentProfile",
                mentor_profile_ids,
                "MentorProfile").uniq
    end

    unless filter.text.blank?
      sanitized_text = sanitize_string_for_elasticsearch_string_query(filter.text)

      results = teams.search({
        query: {
          query_string: {
            query: "*#{sanitized_text}*"
          },
        },
        from: 0,
        size: 10_000
      }).results
      teams = teams.where(id: results.flat_map { |r| r._source.id })
    end

    divisions = Division.where(name: filter.division_enums)
    teams = teams.where(division: divisions)

    teams = case filter.spot_available
            when true
              teams.select { |t| t.spot_available? }
            else
              teams
            end

    teams = case filter.has_mentor
            when true
              teams.select { |t| t.mentors.any? }
            when false
              teams.select { |t| t.mentors.empty? }
            else
              teams
            end

    case filter.user.class.name
    when "StudentProfile"
      teams.select(&:accepting_student_requests?)
    when "MentorProfile"
      teams.select(&:accepting_mentor_requests?)
    else
      teams
    end
  end

  def self.sanitize_string_for_elasticsearch_string_query(str)
    # Escape special characters
    # http://lucene.apache.org/core/old_versioned_docs/versions/2_9_1/queryparsersyntax.html#Escaping Special Characters
    escaped_characters = Regexp.escape('\\+-&|!(){}[]^~*?:')
    str = str.gsub(/([#{escaped_characters}])/, '\\\\\1')

    # AND, OR and NOT are used by lucene as logical operators. We need
    # to escape them
    ['AND', 'OR', 'NOT'].each do |word|
      escaped_word = word.split('').map {|char| "\\#{char}" }.join('')
      str = str.gsub(/\s*\b(#{word.upcase})\b\s*/, " #{escaped_word} ")
    end

    # Escape odd quotes
    quote_count = str.count '"'
    str = str.gsub(/(.*)"(.*)/, '\1\"\3') if quote_count % 2 == 1

    str
  end
end
