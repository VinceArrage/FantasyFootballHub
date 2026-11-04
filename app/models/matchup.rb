class Matchup < ApplicationRecord
  belongs_to :league
  belongs_to :team

  def opponent
    return if matchup_id.nil?

    league.matchups.where(week:, matchup_id:).where.not(team_id:).first
  end
end
