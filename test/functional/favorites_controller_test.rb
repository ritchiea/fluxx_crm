require 'test_helper'

class FavoritesControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    @org1 = Organization.make
  end
  
  test "should create favorite" do
    assert_difference('Favorite.count') do
      post :create, :favorite => {:favorable_type => @org1.class.name, :favorable_id => @org1.id, :user_id => @user1.id}
    end

    # Figure out how to determine a 201 and the options therein; some HTTP header in the @response object
    # assert_redirected_to favorite_path(assigns(:model))
    
    assert_equal @org1, assigns(:model).favorable
  end

  test "should not create duplicate favorites" do
    dupe_favorite = Favorite.make :favorable_type => @org1.class.name, :favorable_id => @org1.id, :user_id => @user1.id
    assert_difference('Favorite.count', 0) do
      post :create, :favorite => {:favorable_type => @org1.class.name, :favorable_id => @org1.id, :user_id => @user1.id}
    end
  end
  
  test "should destroy favorite" do
    favorite = Favorite.make :favorable_type => @org1.class.name, :favorable_id => @org1.id, :user_id => @user1.id
    assert_difference('Favorite.count', -1) do
      delete :destroy, :id => favorite.to_param
    end
  end
end
