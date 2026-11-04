class SyncRun < ApplicationRecord
  KINDS = %w[players leagues projections live].freeze
  RETENTION = 7.days

  validates :kind, inclusion: { in: KINDS }

  after_update_commit :broadcast_stamps, if: -> { saved_change_to_finished_at? }

  scope :succeeded, -> { where.not(finished_at: nil).where(error: nil) }

  def self.last_success(kind) = succeeded.where(kind:).order(finished_at: :desc).first

  # Runs the block and records the outcome. A failure is stored, never raised,
  # so a bad sync leaves existing data in place and shows up as stale.
  def self.track(kind)
    run = create!(kind:, started_at: Time.current)
    yield
    run.update!(finished_at: Time.current)
    true
  rescue StandardError => e
    Rails.logger.error("SyncRun #{kind} failed: #{e.class}: #{e.message}") unless e.is_a?(Sleeper::Error)
    run&.update!(finished_at: Time.current, error: "#{e.class.name.demodulize}: #{e.message}".truncate(500))
    false
  end

  def self.prune(now: Time.current) = where(started_at: ...(now - RETENTION)).delete_all

  def succeeded? = finished_at.present? && error.nil?

  private

  def broadcast_stamps
    broadcast_replace_later_to :sync_status, target: "sync_stamps", partial: "shared/sync_stamps"
  end
end
