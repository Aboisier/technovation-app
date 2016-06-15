class ScoreQuestion < ActiveRecord::Base
  belongs_to :score_category
  has_many :score_values, dependent: :destroy

  accepts_nested_attributes_for :score_values, allow_destroy: true

  validates :label, presence: true, uniqueness: { scope: :score_category_id }
end
