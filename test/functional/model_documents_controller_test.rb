require 'test_helper'

class ModelDocumentsControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    @model_doc = ModelDocument.make(:documentable => User.make)
  end
  
  # test "should create model document" do
  #   assert_difference('ModelDocument.count') do
  #     post :create, :model_document => {:document => Sham.document}
  #   end
  # end
  
  test "should destroy model_document" do
    delete :destroy, :id => @model_doc.to_param
    assert_not_nil @model_doc.reload().deleted_at 
  end
end
