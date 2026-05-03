class PersonalAccessTokensController < ApplicationController
  before_action :require_authentication

  def index
    @tokens = current_user.personal_access_tokens.active.order(created_at: :desc)
    @revoked_tokens = current_user.personal_access_tokens.where.not(revoked_at: nil).order(revoked_at: :desc)
    @just_created_token = flash[:created_token]
  end

  def new
    @token = current_user.personal_access_tokens.build
  end

  def create
    @token = current_user.personal_access_tokens.build(token_params)

    if @token.save
      flash[:created_token] = @token.token
      redirect_to personal_access_tokens_path, notice: "Token created. Copy it now — you won't be able to see it again."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    token = current_user.personal_access_tokens.find(params[:id])
    token.revoke!
    redirect_to personal_access_tokens_path, notice: "Token revoked."
  end

  private

  def token_params
    params.require(:personal_access_token).permit(:name)
  end
end
