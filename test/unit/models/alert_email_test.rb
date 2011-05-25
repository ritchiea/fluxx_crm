require 'test_helper'

class AlertEmailTest < ActiveSupport::TestCase
  test "delivery of all alert emails" do
    recipient1 = User.make(:email => "johndoe@fakemailaddress.com")
    recipient2 = User.make(:email => "janedoe@fakemailaddress.com")
    project = Project.make(:created_by_id => recipient2.id)
    Alert.attr_recipient_role(:creator, :recipient_finder => lambda{|model| model.created_by})
    alert = Alert.make
    alert.alert_recipients.create!(:user_id => recipient1.id)
    alert.alert_recipients.create!(:rtu_model_user_method => :creator)
    rtu = RealtimeUpdate.make(:type_name => Project, :model_id => project.id)
    RealtimeUpdate.where(:type_name => 'Musician').each(&:destroy)
    AlertEmail.enqueue(:alert, :alert => alert, :realtime_update => rtu)
    AlertEmail.deliver_all

    assert_equal 2, ActionMailer::Base.deliveries.size
    assert_equal ["johndoe@fakemailaddress.com", "janedoe@fakemailaddress.com"], ActionMailer::Base.deliveries.map{|e| e["to"].value}
    assert_equal "the subject for johndoe@fakemailaddress.com", ActionMailer::Base.deliveries.first.subject
    assert_equal "the body for johndoe@fakemailaddress.com", ActionMailer::Base.deliveries.first.body.to_s
    assert_equal "the subject for janedoe@fakemailaddress.com", ActionMailer::Base.deliveries.last.subject
    assert_equal "the body for janedoe@fakemailaddress.com", ActionMailer::Base.deliveries.last.body.to_s
  end
end

