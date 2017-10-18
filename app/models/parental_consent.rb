class ParentalConsent < ActiveRecord::Base
  belongs_to :student_profile

  scope :nonvoid, -> { where('voided_at IS NULL') }
  scope :void, -> { where('voided_at IS NOT NULL') }

  validates :electronic_signature, presence: true

  delegate :email,
           :first_name,
           :full_name,
           :consent_token,
           :locale,
    to: :student_profile,
    prefix: true

  after_commit -> {
    after_create_student_actions
    after_create_parent_actions
  }, on: :create

  def student_profile_consent_token=(token)
    self.student_profile = StudentProfile.joins(:account)
      .find_by("accounts.consent_token = ?", token)
  end

  def signed_at
    created_at
  end

  def void!
    update_attributes(voided_at: Time.current)
  end

  def voided?
    !!voided_at
  end
  alias void? voided?

  def after_create_student_actions
    SubscribeEmailListJob.perform_later(
      student_profile_email,
      student_profile_full_name,
      "STUDENT_LIST_ID"
    )

    AccountMailer.confirm_next_steps(self).deliver_later
  end

  def after_create_parent_actions
    if newsletter_opt_in?
      SubscribeEmailListJob.perform_later(student_profile.parent_guardian_email,
                                          student_profile.parent_guardian_name,
                                          "PARENT_LIST_ID")
    end

    ParentMailer.confirm_consent_finished(id).deliver_later
    unless Rails.env.test?
      # TODO: entire test suite requires rewrite due to "wait: 3.days"
      ParentMailer.thank_you(id).deliver_later(wait: 3.days)
    end
  end
end
