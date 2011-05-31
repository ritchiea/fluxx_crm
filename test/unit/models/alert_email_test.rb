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

  test "send_at column is set to a fixed period of time since the last email with the same alert/model pair" do
    model = Project.make
    alert = Alert.make
    other_model = Project.make
    other_alert = Alert.make

    sent_matching_email = AlertEmail.create!(:alert => alert, :model => model, :delivered => true, :send_at => 6.days.ago)
    last_sent_matching_email = AlertEmail.create!(:alert => alert, :model => model, :delivered => true, :send_at => 5.days.ago)
    sent_email_that_does_not_match_the_model = AlertEmail.create!(:alert => alert, :model => other_model, :delivered => true, :send_at => 4.days.ago)
    sent_email_that_does_not_match_the_alert = AlertEmail.create!(:alert => other_alert, :model => model, :delivered => true, :send_at => 3.days.ago)

    new_alert_email = AlertEmail.enqueue(:alert, :alert => alert, :model => model)
    AlertEmail.stubs(:minimum_time_between_emails).returns(1.day)

    assert new_alert_email.send_at == (last_sent_matching_email.send_at + 1.day)
  end

  test "don't enqueue a new email if there's already an unsent email for the same alert/model pair" do
    model = Project.make
    alert = Alert.make

    existent_alert_email = AlertEmail.enqueue(:alert, :alert => alert, :model => model)
    new_alert_email = AlertEmail.enqueue(:alert, :alert => alert, :model => model)

    assert_equal [existent_alert_email], AlertEmail.all
  end
end

