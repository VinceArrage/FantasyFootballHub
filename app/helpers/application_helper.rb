module ApplicationHelper
  SYNC_LABELS = { "players" => "Players & injuries", "leagues" => "Leagues", "projections" => "Projections",
                  "live" => "Live scores" }.freeze
  # Roughly two missed sync intervals (see Sync::CatchUp) before a stamp turns red.
  STALE_AFTER = { "players" => 26.hours, "leagues" => 3.hours, "projections" => 26.hours }.freeze

  def sync_stamp(kind)
    last = SyncRun.where(kind:).where.not(finished_at: nil).order(finished_at: :desc).first
    success = SyncRun.last_success(kind)
    # Live scores only run during games, so "never" there is normal.
    limit = STALE_AFTER[kind]
    stale = limit && (success.nil? || success.finished_at < limit.ago)
    text = success ? "#{time_ago_in_words(success.finished_at)} ago" : "never"
    text += " (last try failed)" if last && !last.succeeded?
    tag.span("#{SYNC_LABELS.fetch(kind)}: #{text}", class: [ "whitespace-nowrap", stale ? "text-red-600" : "text-gray-500" ])
  end

  def points(value) = number_with_precision(value.to_f, precision: 1)
end
