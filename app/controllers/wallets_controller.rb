class WalletsController < ApplicationController
  before_filter :authenticate_user!
  include WalletsHelper

  def refund
  flash[:notice] = create_refund(wallet_params) ? "Amount will reflect in your account within 3-4 days"  : "Unable to refund"
  redirect_to :back
  end

  def show_refund
    render json: {html: render_to_string('show_refund.html.haml', layout: false)}
  end

  def show
    render layout: 'users'
  end

  private

  def wallet_params
  	params.require(:amount)
  end
end
