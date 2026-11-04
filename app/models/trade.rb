class Trade < ApplicationRecord
  belongs_to :league

  scope :recent_first, -> { order(executed_at: :desc) }

  def teams = league.teams.where(sleeper_roster_id: roster_ids)

  # { Team => [Player] } received by each side.
  def received
    players = Player.where(sleeper_id: adds.keys).index_by(&:sleeper_id)
    teams.index_with { |team| adds.select { |_, roster| roster == team.sleeper_roster_id }.keys.filter_map { players[_1] } }
  end

  def picks_for(team) = draft_picks.select { _1["owner_id"] == team.sleeper_roster_id }
end
