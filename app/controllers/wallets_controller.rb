class WalletsController < ApplicationController
  before_filter :authenticate_user!
  def topup
  end

  def refund
	flash[:notice] = current_user.wallet_refund(wallet_params)
	redirect_to :back
  end

  def refund
  flash[:notice] = current_user.wallet_topup(wallet_params)
  redirect_to :back
  end

  def show
  	render layout: 'users'
  end

  private

  def wallet_params
  	params.require(:amount)
  end
end
