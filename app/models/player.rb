class Player < ApplicationRecord
  OUT_STATUSES = %w[Out IR PUP Sus NA].freeze

  has_many :roster_spots, dependent: :destroy

  def out? = OUT_STATUSES.include?(injury_status)
  def injured? = injury_status.present?
end
