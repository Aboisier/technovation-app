module RegionalAmbassador
  class TeamsController < RegionalAmbassadorController
    include DatagridUser

    use_datagrid with: TeamsGrid,
      html_scope: ->(scope, user, params) {
        scope.in_region(user).page(params[:page])
      },
      csv_scope: "->(scope, user, params) { scope.in_region(user) }"

    def show
      @team = Team.in_region(current_ambassador).find(params[:id])
    end

    private
    def grid_params
      grid = (params[:teams_grid] ||= {}).merge(
        admin: false,
        allow_state_search: current_ambassador.country != "US",
        country: [current_ambassador.country],
        state_province: (
          if current_ambassador.country == "US"
            [current_ambassador.state_province]
          else
            Array(params[:teams_grid][:state_province])
          end
        ),
        season: params[:teams_grid][:season] || Season.current.year,
      )

      grid.merge(
        column_names: detect_extra_columns(grid),
      )
    end
  end
end
