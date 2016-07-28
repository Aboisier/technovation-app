class ConsentWaiversController < ApplicationController
  def show
    @consent_waiver = ConsentWaiver.find(params.fetch(:id))
  end

  def new
    if valid_token?
      @consent_waiver = ConsentWaiver.new
    else
      redirect_to application_dashboard_path,
                  alert: t("controllers.consent_waivers.new.unauthorized")
    end
  end

  def create
    @consent_waiver = ConsentWaiver.new(consent_waiver_params)

    if @consent_waiver.save
      redirect_to consent_waiver_path(@consent_waiver),
                  success: t("controllers.consent_waivers.create.success")
    else
      render :new
    end
  end

  private
  def valid_token?
    Account.exists?(consent_token: params.fetch(:token) { "" })
  end

  def consent_waiver_params
    params.require(:consent_waiver).permit(:account_consent_token,
                                           :consent_confirmation,
                                           :electronic_signature)
  end
end
