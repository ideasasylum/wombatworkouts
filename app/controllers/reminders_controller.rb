class RemindersController < ApplicationController
  before_action :require_authentication
  before_action :set_reminder, only: [:update, :destroy]

  def index
    @reminders = current_user.reminders.includes(:program).order(created_at: :desc)
  end

  def create
    @program = current_user.programs.find_by(id: reminder_params[:program_id])

    unless @program
      render json: {error: "Program not found or you don't have permission"}, status: :unprocessable_entity
      return
    end

    @reminder = current_user.reminders.build(reminder_params)
    @reminder.program = @program

    if @reminder.save
      redirect_to reminders_path, notice: "Reminder created successfully"
    else
      render :index, status: :unprocessable_entity
    end
  end

  def update
    return unless @reminder

    if @reminder.update(reminder_params)
      redirect_to reminders_path, notice: "Reminder updated successfully"
    else
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    return unless @reminder

    @reminder.destroy
    redirect_to reminders_path, notice: "Reminder deleted successfully"
  end

  private

  def set_reminder
    @reminder = current_user.reminders.find_by(id: params[:id])

    unless @reminder
      redirect_to reminders_path, alert: "Reminder not found"
    end
  end

  def reminder_params
    params.require(:reminder).permit(:program_id, :time, :timezone, :enabled, days_of_week: [])
  end
end
