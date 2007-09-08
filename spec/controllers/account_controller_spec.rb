require File.dirname(__FILE__) + '/../spec_helper'

context "The AccountController" do
  controller_name 'account'
  
  setup do
    @contest = mock("contest")
    @contest.stub!(:to_param).and_return('1_widesib')
    
    @user = mock("user")
    @user.stub!(:to_param).and_return('2_vasya')
    
    @team = mock("team")
    @team.stub!(:contest).and_return(@contest)
    
    @password_set = mock("password_set")
    
    @password = mock("password")
    @password.stub!(:password_set).and_return(@password_set)
  
    request.env["HTTP_REFERER"] = "http://localhost/test"
    
    @anon_user = mock("anonymous_user")
  end
  
  specify "should log in a valid user and redirect him back" do
    @password_set.stub!(:principal).and_return(@user)
    Password.should_receive(:authenticate).with('secret').and_return(@password)
    @user.should_receive(:last_login_at=)
    @user.should_receive(:save!)
    get :login, :password => 'secret'
    flash[:login_failure].should be_nil
    response.should redirect_to("http://localhost/test")
  end
  
  specify "should log in a valid team and redirect it to participation" do
    @password_set.stub!(:principal).and_return(@team)
    Password.should_receive(:authenticate).with('secret').and_return(@password)
    @team.should_receive(:last_login_at=)
    @team.should_receive(:save!)
    @team.should_receive(:is_a?).with(Team).and_return(true)
    get :login, :password => 'secret'
    flash[:login_failure].should be_nil
    response.should redirect_to(team_participation_url(@contest, @team))
  end
  
  specify "should not log in with an incorrect password" do
    Password.should_receive(:authenticate).with('badsecret').and_return(nil)
    get :login, :password => 'badsecret'
    flash[:login_failure].should == true
    response.should redirect_to("http://localhost/test")
  end
  
  specify "should log out a user" do
    request.session['user'] = @user 
    AnonymousUser.should_receive(:new).and_return(@anon_user)
    get :logout
    session['user'].should == @anon_user
    response.should redirect_to(home_url)
  end
end

