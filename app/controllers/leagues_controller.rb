class LeaguesController < ApplicationController
  before_action :set_league

  def show
    @my_team = @league.my_team
  end

  def waivers
    @waivers = Recommendations::WaiverRanker.new(@league, values:, trending: Recommendations::Trending.adds).call
  end

  def trades
  end

  def trade_log
    @trades = @league.trades.recent_first
  end

  private

  def set_league
    @league = League.find(params[:id])
  end

  def values
    @values ||= Valuation::PlayerValues.new(@league, week: Nfl::Calendar.week)
  end
  helper_method :values
end
