class SignupAttempt < ActiveRecord::Base
  include Casting::Client
  delegate_missing_methods

  geocoded_by :address_details
  reverse_geocoded_by :latitude, :longitude do |attempt, results|
    attempt.update_address_details_from_reverse_geocoding(results)
  end

  has_secure_password validations: false

  enum status: %i{
    pending
    active
    registered
    temporary_password
    wizard
  }

  enum profile_choice: %w{
    student
    mentor
    judge
    regional_ambassador
  }

  enum referred_by: REFERRED_BY_OPTIONS
  enum gender_identity: GENDER_IDENTITY_OPTIONS
  enum mentor_type: MENTOR_TYPE_OPTIONS

  belongs_to :account, required: false

  has_many :mentor_profile_expertises,
    dependent: :destroy

  has_many :expertises,
    through: :mentor_profile_expertises

  accepts_nested_attributes_for :mentor_profile_expertises,
    allow_destroy: true,
    reject_if: :all_blank

  before_validation -> {
    self.email = (email || "").strip.downcase
  }

  validates :email, presence: true, email: true, if: :email_required?

  validates :password,
   presence: true,
   length: { minimum: 8 },
   if: :password_required?

  has_secure_token :pending_token
  has_secure_token :activation_token
  has_secure_token :signup_token
  has_secure_token :admin_permission_token
  has_secure_token :wizard_token

  def state
    FriendlySubregion.(self, with_prefix: false)
  end

  def country
    me = OpenStruct.new(country: '', address_details: [city, state, country_code].join(", "))
    FriendlyCountry.new(me).country_name
  end

  def assign_address_details(geocoded)
    self.city = geocoded.city
    self.state_code = geocoded.state_code
    self.country_code = geocoded.country_code
  end

  def address_details
    [city, state, country].reject(&:blank?).join(", ")
  end

  def email_required?
    new_record? && !wizard? && !terms_agreed?
  end

  def terms_agreed?
    !!terms_agreed_at
  end

  def profile_choice
    self['profile_choice'] || ('student' if can_be_student?)
  end

  def set_terms_agreed(bool)
    value = bool ? Time.current : nil
    self.terms_agreed_at = value
    save!
  end

  def update_address_details_from_reverse_geocoding(results)
    return false if results.none?

    result = results.first

    self.city = result.city
    self.state_code = result.state_code

    address_details = [
      result.city,
      result.state,
      result.country,
    ].reject(&:blank?).join(", ")

    geo = OpenStruct.new(address_details: address_details)

    self.country_code = FriendlyCountry.new(geo).country_code
  end

  private
  def can_be_student?
    Account.new(
      date_of_birth: Date.new(
        birth_year || Date.today.year - 10,
        birth_month || 1,
        birth_day || 1
      ),
    ).age_by_cutoff < 19 &&
      gender_identity != 'Male'
  end
end