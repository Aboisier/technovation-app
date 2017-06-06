module Student
  class DashboardsController < StudentController
    helper_method :unofficial_scores?

    def show
      @regional_events = RegionalPitchEvent.available_to(current_team.submission)

      if current_team.submission.present? and ENV["ENABLE_TEAM_SCORES"]
        @all_scores = current_team.submission.submission_scores.complete
        @quarterfinals_scores = @all_scores.quarterfinals

        if @quarterfinals_scores.any?
          @qf_ideation_average = category_average(:ideation, :quarterfinals)
          @qf_technical_average = category_average(:technical, :quarterfinals)
          @qf_entrepreneurship_average = category_average(:entrepreneurship, :quarterfinals)
          @qf_pitch_average = category_average(:pitch, :quarterfinals)
          @qf_overall_impression_average = category_average(:overall_impression, :quarterfinals)
          @qf_best_category = best_category(:quarterfinals)
        end

        if current_team.submission.contest_rank == "semifinalist"
          @semifinals_scores = @all_scores.semifinals

          @sf_ideation_average = category_average(:ideation, :semifinals)
          @sf_technical_average = category_average(:technical, :semifinals)
          @sf_entrepreneurship_average = category_average(:entrepreneurship, :semifinals)
          @sf_pitch_average = category_average(:pitch, :semifinals)
          @sf_overall_impression_average = category_average(:overall_impression, :semifinals)
          @sf_best_category = best_category(:semifinals)
        end

      end
    end

    private

    def category_average(category, round)
      if round == :semifinals
        scores = @semifinals_scores
      else
        scores = @quarterfinals_scores
      end
      sum = scores.official.inject(0.0) do |acc, score|
        acc += score.public_send("#{category}_total")
      end
      (sum / scores.official.count.to_f).round(2)
    end

    def unofficial_scores?
      not @quarterfinals_scores.all?(&:official?)
    end

    def best_category(round)
      if round == :semifinals
        adjusted_scores = {
          "Overall Impression": (@sf_overall_impression_average * 20/25),
          "Pitch": @sf_pitch_average,
          "Entrepreneurship":  @sf_entrepreneurship_average,
          "Technical": @sf_technical_average,
          "Ideation": (@sf_ideation_average * 20/15)
        }
      else
        adjusted_scores = {
          "Overall Impression": (@qf_overall_impression_average * 20/25),
          "Pitch": @qf_pitch_average,
          "Entrepreneurship":  @qf_entrepreneurship_average,
          "Technical": @qf_technical_average,
          "Ideation": (@qf_ideation_average * 20/15)
        }
      end
      adjusted_scores.max_by { |_,v| v }[0]
    end

  end
end
