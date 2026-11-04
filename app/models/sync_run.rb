class SyncRun < ApplicationRecord
  KINDS = %w[players leagues projections live].freeze

  validates :kind, inclusion: { in: KINDS }

  scope :succeeded, -> { where.not(finished_at: nil).where(error: nil) }

  def self.last_success(kind) = succeeded.where(kind:).order(finished_at: :desc).first

  # Runs the block and records the outcome. A Sleeper failure is stored, never raised,
  # so a bad sync leaves existing data in place and shows up as stale.
  def self.track(kind)
    run = create!(kind:, started_at: Time.current)
    yield
    run.update!(finished_at: Time.current)
    true
  rescue Sleeper::Error => e
    run&.update!(finished_at: Time.current, error: e.message)
    false
  end

  def succeeded? = finished_at.present? && error.nil?
end
