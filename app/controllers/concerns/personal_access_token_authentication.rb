module PersonalAccessTokenAuthentication
  extend ActiveSupport::Concern

  private

  attr_reader :current_user

  def authenticate_personal_access_token!
    pat = bearer_token.present? ? PersonalAccessToken.authenticate(bearer_token) : nil

    if pat
      @current_user = pat.user
      pat.touch_last_used!
    else
      response.headers["WWW-Authenticate"] = 'Bearer realm="Wombat Workouts"'
      render json: {error: "unauthorized"}, status: :unauthorized
    end
  end

  def bearer_token
    header = request.headers["Authorization"]
    return nil if header.blank?

    match = header.match(/\ABearer (?<token>.+)\z/)
    match && match[:token].strip
  end
end
