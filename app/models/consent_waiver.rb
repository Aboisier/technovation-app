class ConsentWaiver < ActiveRecord::Base
  belongs_to :account

  validates :electronic_signature, presence: true
  validates :consent_confirmation, inclusion: { in: [1] }

  delegate :full_name, :type_name, to: :account, prefix: true

  after_create :enable_searchable_users

  def account_consent_token=(token)
    self.account = Account.find_by(consent_token: token)
  end

  def signed_at
    created_at
  end

  private
  def enable_searchable_users
    account.enable_searchability
  end
end
