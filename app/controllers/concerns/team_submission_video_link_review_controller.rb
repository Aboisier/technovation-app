module TeamSubmissionVideoLinkReviewController
  extend ActiveSupport::Concern

  def update
    submission = current_profile.team_submissions.current.friendly.find(video_link_params[:id])
    submission.update({ video_link_params[:piece] => video_link_params[:value] })
    redirect_to [current_scope, :team_submission_section, id: submission.to_param, section: :pitch],
      success: "You saved your #{params[:piece].humanize}!"
  end

  private
  def video_link_params
    params.permit(:piece, :value, :id)
  end
end