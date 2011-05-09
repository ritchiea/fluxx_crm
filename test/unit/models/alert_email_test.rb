require 'test_helper'

class AlertEmailTest < ActiveSupport::TestCase
  def setup
  end

  test "delivery of all alert emails" do
    recipient1 = User.make(:email => "johndoe@fakemailaddress.com")
    recipient2 = User.make(:email => "janedoe@fakemailaddress.com")
    project = Project.make(:created_by_id => recipient2.id)
    template = AlertEmailTemplate.make(:name => :test_alert)
    alert = Alert.make(:alert_email_template => template)
    alert.alert_recipients.create!(:user_id => recipient1.id)
    alert.alert_recipients.create!(:rtu_model_user_method => :created_by_id)
    rtu = RealtimeUpdate.make(:model_class => Project, :model_id => project.id)
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

