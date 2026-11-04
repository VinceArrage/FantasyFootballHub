class DashboardController < ApplicationController
  def show
    @leagues = League.where(season: current_season).order(:name).includes(:teams)
  end

  private

  def current_season
    League.maximum(:season)
  end
end
