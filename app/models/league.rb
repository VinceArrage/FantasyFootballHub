class League < ApplicationRecord
  NON_STARTER_SLOTS = %w[BN IR TAXI].freeze

  has_many :teams, dependent: :destroy
  has_many :matchups, dependent: :destroy

  def my_team = teams.find_by(mine: true)

  def starter_slots = roster_positions - NON_STARTER_SLOTS

  # Last week that matters for value: the fantasy championship week.
  def playoff_end_week
    start = settings.fetch("playoff_week_start", 15).to_i
    teams_in = settings.fetch("playoff_teams", 6).to_i
    start + Math.log2([ teams_in, 2 ].max).ceil - 1
  end

  def faab? = settings["waiver_type"].to_i == 2
end
