class SetupController < ApplicationController
  skip_before_action :require_account

  def new
    @username = Account.current&.sleeper_username
  end

  def create
    username = params.require(:username).strip.downcase
    user = Sleeper::Client.new.user(username)
    if user.blank?
      flash.now[:alert] = "No Sleeper user named \"#{username}\"."
      @username = username
      return render :new, status: :unprocessable_entity
    end

    Account.delete_all
    Account.create!(sleeper_username: username, sleeper_user_id: user["user_id"])
    %w[players leagues projections].each { |kind| SyncJob.perform_later(kind) }
    redirect_to root_path, notice: "Linked #{user['display_name']}. First sync is running."
  rescue Sleeper::Error => e
    flash.now[:alert] = "Couldn't reach Sleeper: #{e.message}"
    render :new, status: :service_unavailable
  end
end
