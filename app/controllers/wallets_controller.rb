class WalletsController < ApplicationController
  before_filter :authenticate_user!
  def topup
  end

  def refund
	flash[:notice] = current_user.wallet_refund(refund_params)
	redirect_to :back
  end

  def show
  	
  end

  private

  def refund_params
  	params.require(:amount)
  end
end
