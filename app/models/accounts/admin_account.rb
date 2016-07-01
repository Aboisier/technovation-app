class AdminAccount < Account
  default_scope { joins(:admin_profile) }

  after_initialize :build_admin_profile

  has_one :admin_profile, foreign_key: :account_id

  delegate :scores,
           :scored_submission_ids,
    to: :admin_profile, prefix: false

  def admin?
    true
  end

  def profile_id
    admin_profile.id
  end
end
