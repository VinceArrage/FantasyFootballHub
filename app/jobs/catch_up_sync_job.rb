class CatchUpSyncJob < ApplicationJob
  queue_as :default

  def perform
    return unless Account.current

    Sync::CatchUp.new.due_kinds.each { |kind| SyncJob.perform_later(kind) }
  end
end
