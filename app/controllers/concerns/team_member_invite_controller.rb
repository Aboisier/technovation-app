module TeamMemberInviteController
  extend ActiveSupport::Concern

  def show
    @invite = current_profile.team_member_invites.find_by(
      invite_token: params.fetch(:id)
    ) || NullInvite.new

    case current_scope
    when "mentor"
      render template: "mentor/mentor_invites/show"
    when "student"
      render template: "team_member_invites/show"
    end
  end

  def create
    @team_member_invite = TeamMemberInvite.new(team_member_invite_params)

    if @team_member_invite.save
      redirect_to [
        current_scope,
        @team_member_invite.team,
        { anchor: "students" }
      ],
      success: t("controllers.team_member_invites.create.success")
    else
      render :new
    end
  end

  def destroy
    if current_profile.team_ids.any?
      @invite = TeamMemberInvite.find_by(
        team_id: current_profile.team_ids,
        invite_token: params.fetch(:id)
      )

      if @invite
        @invite.destroy
        redirect_to [
          current_scope,
          @invite.team,
          { anchor: "students" }
        ],
        success: t("controllers.invites.destroy.success",
                   name: @invite.invitee_name)
      else
        redirect_to [current_scope, :dashboard],
          notice: t("controllers.invites.destroy.not_found")
      end
    else
      redirect_to [current_scope, :dashboard],
        notice: t("controllers.application.general_error")
    end
  end

  private
  def team_member_invite_params
    params.require(:team_member_invite).permit(
      :invitee_email,
      :team_id
    ).tap do |params|
      params[:inviter] = current_profile
    end
  end

  class NullInvite
    def status
      "missing"
    end
  end
end
