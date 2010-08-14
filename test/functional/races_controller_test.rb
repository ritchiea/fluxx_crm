require 'test_helper'

class RacesControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    @race = Race.make
  end
  
  test "should show race" do
    get :show, :id => @race.to_param
    assert_response :success
    assert assigns(:action_buttons)
    assert_equal [[:kick_off, "Kick Off"]], assigns(:action_buttons)
  end
  
  test "should update user" do
    assert_equal 'new', @race.state
    put :update, :id => @race.to_param, :event_action => 'kick_off', :race => {}
    assert flash[:info]
    assert_redirected_to race_path(assigns(:race))
    assert_equal 'beginning', @race.reload.state
  end
  
  test "should generate a workflow event" do
    race = Race.make
    assert_equal 'new', race.state
    assert_difference('WorkflowEvent.count') do
      race.kick_off
      assert_equal 'beginning', race.state
      race.save
    end
    
  end
  
end