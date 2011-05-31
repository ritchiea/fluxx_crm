require 'test_helper'

class AlertEmailTest < ActiveSupport::TestCase
  test "delivery of all alert emails" do
    alert = Alert.make_unsaved
    alert.subject =  "the subject for {{recipient.email}} on project '{{model.title}}'"
    alert.body = "the body for {{recipient.email}} on project '{{model.title}}'"
    alert.save!

    johndoe = User.make(:email => "johndoe@fakemailaddress.com")
    alert.alert_recipients.create!(:user_id => johndoe.id)

    janedoe = User.make(:email => "janedoe@fakemailaddress.com")
    project = Project.make(:title => "conquer the world", :created_by_id => janedoe.id)
    alert.alert_recipients.create!(:rtu_model_user_method => :creator)

    rtu = RealtimeUpdate.make(:type_name => Project, :model_id => project.id)
    Alert.attr_recipient_role(:creator, :recipient_finder => lambda{|model| model.created_by})
    RealtimeUpdate.where(:type_name => 'Musician').each(&:destroy)
    AlertEmail.enqueue(:alert, :alert => alert, :model => rtu.model)
    AlertEmail.deliver_all

    assert_equal 2, ActionMailer::Base.deliveries.size
    assert_equal ["johndoe@fakemailaddress.com", "janedoe@fakemailaddress.com"], ActionMailer::Base.deliveries.map{|e| e["to"].value}
    assert_equal "the subject for johndoe@fakemailaddress.com on project 'conquer the world'", ActionMailer::Base.deliveries.first.subject
    assert_equal "the body for johndoe@fakemailaddress.com on project 'conquer the world'", ActionMailer::Base.deliveries.first.body.to_s
    assert_equal "the subject for janedoe@fakemailaddress.com on project 'conquer the world'", ActionMailer::Base.deliveries.last.subject
    assert_equal "the body for janedoe@fakemailaddress.com on project 'conquer the world'", ActionMailer::Base.deliveries.last.body.to_s
  end
end

