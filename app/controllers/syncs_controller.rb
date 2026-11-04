class SyncsController < ApplicationController
  def create
    %w[players leagues projections].each { |kind| SyncJob.perform_later(kind) }
    redirect_back fallback_location: root_path, notice: "Sync started."
  end
end
