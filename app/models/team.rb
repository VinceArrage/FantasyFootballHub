class Team < ApplicationRecord
  belongs_to :league
  has_many :roster_spots, dependent: :delete_all
  has_many :players, through: :roster_spots
  has_many :matchups, dependent: :destroy

  scope :standings, -> { order(wins: :desc, points_for: :desc) }

  def starters = roster_spots.where(starter: true).order(:slot_index).includes(:player).map(&:player)
  def bench = roster_spots.where(starter: false).includes(:player).map(&:player)
  def record = "#{wins}-#{losses}#{"-#{ties}" if ties.positive?}"
  def display_name = owner_name.presence || "Team #{sleeper_roster_id}"
end
