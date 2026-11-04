class DashboardController < ApplicationController
  def show
    @leagues = League.where(season: current_season).order(:name).includes(:teams)
    @week = Nfl::Calendar.week
    @trending = Recommendations::Trending.adds
  end

  private

  def current_season
    League.maximum(:season)
  end
end
