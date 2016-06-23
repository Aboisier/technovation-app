class AuthenticationsController < ApplicationController
  include AuthenticationController

  before_filter :authenticate_account!

  helper_method :current_account

  def edit
    authentication
  end

  def update
    if authentication.update_attributes(auth_params)
      redirect_to authentication_path,
                  success: t('controllers.authentications.update.success')
    else
      render :edit
    end
  end

  private
  def authentication
    @authentication ||= Authentication.find_with_token(cookies.fetch(:auth_token) { "" })
  end

  def current_account
    @current_authentication ||= Authentication.find_with_token(cookies.fetch(:auth_token) { "" })
  end

  def authenticate_account!
    FindAuthenticationRole.authenticate(:basic, cookies, failure: -> {
      save_redirected_path && go_to_signin
    })
  end
end
