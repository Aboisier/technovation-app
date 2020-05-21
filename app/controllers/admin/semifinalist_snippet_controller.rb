module Admin
  class SemifinalistSnippetController < AdminController
    layout false

    def show
      senior_submissions = TeamSubmission
        .current
        .semifinalist
        .filter { |sub| sub.senior_division? }
      @senior_columns = split_into_columns(senior_submissions)

      junior_submissions = TeamSubmission
        .current
        .semifinalist
        .filter { |sub| sub.junior_division? }
      @junior_columns = split_into_columns(junior_submissions)

      respond_to :html, :text
    end

    private

    def group_by_country(submissions)
      submissions
        .group_by(&:country)
        .map { |k, v| [k.nil? ? '' : k, v] }
        .to_h
    end

    def entry_for(country, submissions)
      friendly_name = FriendlyCountry.(
        OpenStruct.new(address_details: country),
        prefix: false,
        source: :country_code,
      )

      {
        country: country,
        friendly_name: friendly_name,
        submissions: submissions.sort_by { |sub| sub.team_name.downcase }
      }
    end

    def split_into_columns(subs)
      left_col = []
      right_col = []

      total_subs = subs.count
      subs_in_left_column = 0

      group_by_country(subs).sort.each do |country, submissions|
        if subs_in_left_column < (total_subs / 2)
          left_col << entry_for(country, submissions)
          subs_in_left_column = subs_in_left_column + submissions.count
        else
          right_col << entry_for(country, submissions)
        end
      end

      [left_col, right_col]
    end
  end
end
