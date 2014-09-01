class WalletsController < ApplicationController
  before_filter :authenticate_user!
  include WalletsHelper

  def refund
    if create_refund(wallet_params)
      flash[:notice] = "Your refund has been initiated and it should reach you in 4-5 days"
    else
      flash[:error] = "Unable to refund."
    end
  redirect_to :back
  end

  def show_refund
    render json: {html: render_to_string('show_refund.html.haml', layout: false)}
  end

  def show
    render layout: 'users'
  end

  def history
    @history = current_user.wallets.order('created_at DESC').limit(5)
    render json: {html: render_to_string('_history.haml', layout: false)}
  end

  private

  def wallet_params
  	params.require(:amount)
  end
end
