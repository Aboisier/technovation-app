module Student
  class TeamMembershipsController < StudentController
    def destroy
      team = current_student.teams.find(params.fetch(:id))
      TeamRosterManaging.remove(team, current_student)

      redirect_to student_dashboard_path,
        success: t("controllers.team_memberships.destroy.success",
                   name: team.name)
    end
  end
end
