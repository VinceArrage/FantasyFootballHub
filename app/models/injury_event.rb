class InjuryEvent < ApplicationRecord
  belongs_to :player

  scope :recent, -> { order(observed_at: :desc).limit(25) }

  after_create_commit -> { broadcast_prepend_later_to :injuries, target: "injury_feed" }

  def cleared? = to_status.nil?

  # Only events for players on one of my rosters matter on the dashboard.
  def self.for_my_players
    where(player_id: RosterSpot.joins(:team).where(teams: { mine: true }).select(:player_id))
  end
end
