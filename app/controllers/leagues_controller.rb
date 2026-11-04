class LeaguesController < ApplicationController
  before_action :set_league

  def show
    @my_team = @league.my_team
  end

  private

  def set_league
    @league = League.find(params[:id])
  end
end
