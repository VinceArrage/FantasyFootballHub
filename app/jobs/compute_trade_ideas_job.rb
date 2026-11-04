class ComputeTradeIdeasJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(league_id) { "trade_ideas/#{league_id}" }, on_conflict: :discard

  def perform(league_id)
    league = League.find(league_id)
    values = Valuation::PlayerValues.new(league, week: Nfl::Calendar.week)
    ideas = Recommendations::TradeFinder.new(league, values:).call

    TradeIdea.transaction do
      league.trade_ideas.delete_all
      ideas.each { TradeIdea.create!(_1) }
    end

    Turbo::StreamsChannel.broadcast_replace_to(
      [ league, :trade_ideas ], target: ActionView::RecordIdentifier.dom_id(league, :trade_ideas),
      partial: "leagues/trade_ideas", locals: { league: }
    )
  end
end
