class ConnectedAppsController < ApplicationController
  before_action :require_authentication

  def index
    application_ids = Doorkeeper::AccessToken
      .where(resource_owner_id: current_user.id, revoked_at: nil)
      .distinct
      .pluck(:application_id)

    @applications = Doorkeeper::Application.where(id: application_ids).order(:name)
  end

  def destroy
    application = Doorkeeper::Application.find(params[:id])

    Doorkeeper::AccessToken
      .where(application_id: application.id, resource_owner_id: current_user.id, revoked_at: nil)
      .find_each(&:revoke)

    Doorkeeper::AccessGrant
      .where(application_id: application.id, resource_owner_id: current_user.id, revoked_at: nil)
      .find_each(&:revoke)

    redirect_to connected_apps_path, notice: "Access revoked."
  end
end
