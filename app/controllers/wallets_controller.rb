class WalletsController < ApplicationController
  
  before_filter :authenticate_user!
  
  include WalletsHelper

  def refund
    @refunded = true
    if create_refund(wallet_params)
      activities_params = {}
      activities_params[:user_id] = current_user.id
      activities_params[:activity] = Activity::ACTIVITIES[:refund_requested]
      activities_params[:amount] = params[:amount].to_i
      Activity.create_activity(activities_params)
      flash[:notice] = "Your refund has been initiated and it should reach you in 4-5 business days"
    else
      flash[:error] = "Unable to refund."
    end
  render json: {html: render_to_string('show_refund.html.haml', layout: false)}
  end

  def show_refund
    render json: {html: render_to_string('show_refund.html.haml', layout: false)}
  end

  def show
    render layout: 'users'
  end

  def history
    @history = []
    Wallet.unscoped.where(user_id: current_user.id).order('created_at DESC').limit(20).each do |w|
      if w.transferable_id.nil?
        @history << {booking: "N/A", amount: -w.amount, date: "#{w.created_at.strftime('%Y-%m-%d')}", description: (w.status==0 ? "Refund Issued" : "Refund Pending")}
      elsif w.transferable.through== 'wallet_widget'
        next
      elsif w.credit
        @history << {booking: CommonHelper.encode('booking', w.transferable.booking_id), amount: "+ #{w.amount}", date: "#{w.created_at.strftime('%Y-%m-%d')}",
         description: "Added to wallet"}
      else
        @history << {booking: CommonHelper.encode('booking', w.transferable.booking_id), amount: "- #{w.amount}", date: "#{w.created_at.strftime('%Y-%m-%d')}",
         description: "Used from wallet"}
      end
    end
    render json: {html: render_to_string('_history.haml', layout: false)}
  end

  private

  def wallet_params
  	params.require(:amount)
  end
end
