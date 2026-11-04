module Injuries
  # Roster problems for one team, worst first: injured or empty starter slots
  # before bench injuries.
  module Flags
    SEVERITY = { red: 0, orange: 1, yellow: 2 }.freeze

    module_function

    def for(team)
      return [] unless team

      spots = team.roster_spots.includes(:player)
      flags = spots.filter_map do |spot|
        severity = severity(spot.player)
        { player: spot.player, severity:, starter: spot.starter } if severity
      end
      empty = team.league.starter_slots.size - spots.count(&:starter)
      flags += Array.new([ empty, 0 ].max) { { player: nil, severity: :red, starter: true } }
      flags.sort_by { |f| [ f[:starter] ? 0 : 1, SEVERITY[f[:severity]] ] }
    end

    def severity(player)
      return :red if player.out?

      { "Doubtful" => :orange, "Questionable" => :yellow }[player.injury_status]
    end
  end
end
