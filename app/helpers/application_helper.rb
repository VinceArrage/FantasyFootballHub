module ApplicationHelper
  SYNC_LABELS = { "players" => "Players & injuries", "leagues" => "Leagues", "projections" => "Projections",
                  "live" => "Live scores" }.freeze

  def sync_stamp(kind)
    last = SyncRun.where(kind:).where.not(finished_at: nil).order(finished_at: :desc).first
    success = SyncRun.last_success(kind)
    stale = success.nil? || success.finished_at < 26.hours.ago
    text = success ? "#{time_ago_in_words(success.finished_at)} ago" : "never"
    text += " (last try failed)" if last && !last.succeeded?
    tag.span("#{SYNC_LABELS.fetch(kind)}: #{text}", class: [ "whitespace-nowrap", stale ? "text-red-600" : "text-gray-500" ])
  end

  def points(value) = number_with_precision(value.to_f, precision: 1)
end
