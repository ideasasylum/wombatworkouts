class DashboardController < ApplicationController
  before_action :require_authentication

  def index
    # Fetch programs where user is creator OR has workouts for
    # Sort by most recent workout completion date (DESC, NULLS LAST)
    # Limit to 5 records
    @programs = Program
      .left_joins(:workouts)
      .where("programs.user_id = ? OR workouts.user_id = ?", current_user.id, current_user.id)
      .select("programs.*, MAX(workouts.created_at) as last_workout_at")
      .group("programs.id")
      .order(Arel.sql("MAX(workouts.created_at) DESC NULLS LAST"))
      .limit(5)
      .includes(:exercises)

    # Fetch user's 5 most recent workouts with program association
    @workouts = current_user.workouts
      .includes(:program)
      .order(created_at: :desc)
      .limit(5)

    # Calculate boolean flags for "View All" links
    # Check if user has more than 5 programs (created or followed)
    all_programs = Program
      .left_joins(:workouts)
      .where("programs.user_id = ? OR workouts.user_id = ?", current_user.id, current_user.id)
      .distinct

    @has_more_programs = all_programs.count > 5

    # Check if user has more than 5 workouts
    @has_more_workouts = current_user.workouts.count > 5

    @heatmap = WorkoutHeatmap.new(current_user)
  end
end
