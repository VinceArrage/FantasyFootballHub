class TradeIdea < ApplicationRecord
  belongs_to :league
  belongs_to :opponent_team, class_name: "Team"

  def give = Player.where(id: give_ids)
  def get = Player.where(id: get_ids)
end
