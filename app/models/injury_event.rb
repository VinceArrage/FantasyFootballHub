class InjuryEvent < ApplicationRecord
  belongs_to :player

  scope :recent, -> { order(observed_at: :desc).limit(25) }

  # The dashboard feed only lists my players, so only those are pushed live.
  after_create_commit -> { broadcast_prepend_later_to :injuries, target: "injury_feed" }, if: :mine?

  def cleared? = to_status.nil?

  def mine? = self.class.for_my_players.exists?(id)

  # Only events for players on one of my rosters matter on the dashboard.
  def self.for_my_players
    where(player_id: RosterSpot.joins(:team).where(teams: { mine: true }).select(:player_id))
  end
end
