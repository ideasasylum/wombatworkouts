class PushSubscriptionsController < ApplicationController
  before_action :require_authentication

  def create
    @subscription = current_user.push_subscriptions.build(subscription_params)

    if @subscription.save
      head :created
    else
      render json: {errors: @subscription.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def destroy
    @subscription = current_user.push_subscriptions.find_by(id: params[:id])

    if @subscription
      @subscription.destroy
      head :no_content
    else
      head :not_found
    end
  end

  private

  def subscription_params
    params.require(:push_subscription).permit(:endpoint, :p256dh_key, :auth_key)
  end
end
