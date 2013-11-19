require 'spec_helper'

describe Api::UsersController do

  before do
    @user = alice
    sign_in :user, @user
    @controller.stub(:current_user).and_return(@user)
  end

  describe "Accessing api methods" do
    it "without an access token'" do
        @expected = {:error => "300"}.to_json
        get 'get_user_person_list'
        response.body.should == @expected
    end

    it "with an invalid access token" do
        @expected = {:error => "300"}.to_json
        get 'get_user_person_list' ,{'access_token'=> "100"}
        response.body.should == @expected
    end

    it "without profile read permission" do
        @expected = {:error => "310"}.to_json
        @rt = FactoryGirl.create(:refresh_token, :user_guid=> Person.first.guid)
        @at = FactoryGirl.create(:access_token, :refresh_token => @rt.token)
        get 'get_user_person_list' ,{ 'access_token' => @at.token, 'diaspora_handle' => 'alice@localhost:9887' }
        response.body.should == @expected
    end

    it "without registered app" do
        @expected = {:error => "403"}.to_json
        @rt = FactoryGirl.create(:refresh_token, :user_guid=> Person.first.guid)
        @at = FactoryGirl.create(:access_token, :refresh_token => @rt.token)
        get 'get_user_person_list' ,{ 'access_token' => @at.token, 'diaspora_handle' => 'bob@localhost:9887' }
        response.body.should == @expected
    end    

  end

  describe "#get_user_person_list" do

    it "display person list" do
        @rt2 = FactoryGirl.create(:refresh_token2, :user_guid=> Person.first.guid)
        @at2 = FactoryGirl.create(:access_token2, :refresh_token => @rt2.token)
	        @expected={
            :first_name      => Profile.all[2].first_name,
            :last_name       => Profile.all[2].last_name,
            :diaspora_handle => "bob@localhost:9887",
            :location        => Profile.all[2].location,
            :birthday        => Profile.all[2].birthday,
            :gender          => Profile.all[2].gender
        }.to_json

        get 'get_user_person_list' ,{ 'access_token' => @at2.token, 'diaspora_handle' => 'alice@localhost:9887' }
        response.body.should include(@expected)
    end
  end

  describe "#get_users_aspects_list" do

    it "display aspects list" do
        @rt2 = FactoryGirl.create(:refresh_token2, :user_guid=> Person.first.guid)
        @at2 = FactoryGirl.create(:access_token2, :refresh_token => @rt2.token)
	        @expected={
            :aspect_name  => User.first.aspects.first.name,
            :id           => User.first.aspects.first.id,
            :user_id      => User.first.aspects.first.user_id
        }.to_json

        get 'get_users_aspects_list' ,{ 'access_token' => @at2.token, 'diaspora_handle' => 'alice@localhost:9887' }
        response.body.should include(@expected)
    end
  end

  describe "#get_user_followed_tags_list" do

    it "display tag list" do
        @as=FactoryGirl.create(:tag_following)
        @rt2 = FactoryGirl.create(:refresh_token2, :user_guid=> Person.last.guid)
        @at2 = FactoryGirl.create(:access_token2, :refresh_token => @rt2.token)
	        @expected=User.last.followed_tags.to_json

        get 'get_user_followed_tags_list' ,{ 'access_token' => @at2.token, 'diaspora_handle' => User.last.diaspora_handle }
        response.body.should include(@expected)
    end
  end
 
  describe "#get_user_details" do

    it "display user details" do
        @rt2 = FactoryGirl.create(:refresh_token2, :user_guid=> Person.first.guid)
        @at2 = FactoryGirl.create(:access_token2, :refresh_token => @rt2.token)
	        @expected=Person.first.as_json.to_json

        get 'get_user_details' ,{ 'access_token' => @at2.token, 'diaspora_handle' => 'alice@localhost:9887' }
        response.body.should include(@expected)
    end
  end

end
