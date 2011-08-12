class AdminItemsController < ApplicationController
  include FluxxAdminItemsController

  def index
    render :layout => false
  end
end