module Lineup
  # Best starting lineup for a set of slots. Filling the most restrictive slots
  # first (QB before FLEX before SUPER_FLEX) makes greedy optimal for Sleeper's
  # nested flex positions.
  class Optimizer
    ELIGIBLE = {
      "QB" => %w[QB], "RB" => %w[RB], "WR" => %w[WR], "TE" => %w[TE], "K" => %w[K], "DEF" => %w[DEF],
      "FLEX" => %w[RB WR TE], "WRRB_FLEX" => %w[RB WR], "REC_FLEX" => %w[WR TE],
      "SUPER_FLEX" => %w[QB RB WR TE]
    }.freeze

    Result = Data.define(:lineup, :total)

    def self.eligible_positions(slots) = slots.flat_map { ELIGIBLE.fetch(_1, []) }.uniq

    def initialize(slots)
      @slots = slots
    end

    # candidates: [{ player:, points: }]; the caller removes Out/IR players.
    def call(candidates)
      pool = candidates.sort_by { -_1[:points] }
      used = Set.new
      picks = {}
      fill_order.each do |slot, i|
        positions = ELIGIBLE[slot]
        Rails.logger.info("Lineup: unknown slot #{slot}") unless positions
        pick = positions && pool.find { |c| !used.include?(c[:player].id) && positions.include?(c[:player].position) }
        used << pick[:player].id if pick
        picks[i] = pick
      end
      lineup = @slots.each_with_index.map { |slot, i| [ slot, picks[i] ] }
      Result.new(lineup:, total: lineup.sum { |_, c| c ? c[:points] : 0.0 }.round(2))
    end

    private

    def fill_order
      @slots.each_with_index.sort_by { |slot, i| [ ELIGIBLE.fetch(slot, []).size.nonzero? || 99, i ] }
    end
  end
end
