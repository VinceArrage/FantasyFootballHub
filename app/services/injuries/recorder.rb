module Injuries
  # Turns player-sync injury changes into events, then pushes fresh flags to every
  # open page for leagues where one of the changed players is rostered.
  class Recorder
    def self.call(changes, now: Time.current)
      events = changes.map do |c|
        InjuryEvent.create!(player: c[:player], from_status: c[:from], to_status: c[:to], observed_at: now)
      end
      broadcast_flags(changes.map { _1[:player].id })
      events
    end

    def self.broadcast_flags(player_ids)
      return if player_ids.empty?

      League.where(id: Team.joins(:roster_spots).where(roster_spots: { player_id: player_ids }).select(:league_id))
            .find_each do |league|
        Turbo::StreamsChannel.broadcast_replace_later_to(
          [ league, :injuries ], target: ActionView::RecordIdentifier.dom_id(league, :injuries),
          partial: "leagues/injury_flags", locals: { league: }
        )
      end
    end
  end
end
