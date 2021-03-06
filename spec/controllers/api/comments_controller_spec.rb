require 'spec_helper'

describe Api::CommentsController do

  describe "#permissions for scopes," do
    user = FactoryGirl.create(:user)
	  scopes = Array  [ "post_read", "post_delete", "post_write" ]
    rt = FactoryGirl.create(:refresh_token, :user=> user, :scopes=> scopes)
    at = FactoryGirl.create(:access_token, :refresh_token => rt)

    it "without comment read permission" do
      expected = {:error => "320"}.to_json
      get 'get_given_user_comment_list' ,{ 'access_token' => at.token, 'diaspora_handle' => user.diaspora_handle }
      response.body.should == expected
    end

    it "without comment write permission" do
      expected = {:error => "321"}.to_json
	    status= FactoryGirl.create(:status_message,:author=>user.person)
	    text = "Test comment"
      get 'create_comment' ,{ 'access_token' => at.token, 'post_id' => status.id,'text' => text, 'diaspora_handle' => user.diaspora_handle }
      expected = {:error => "321"}.to_json
    end

    it "without comment delete permission" do
      expected = {:error => "322"}.to_json
	    status= FactoryGirl.create(:status_message,:author=>user.person)
      comment = FactoryGirl.create(:comment,:post=>status,:author=>user.person)
      get 'delete_comment' ,{ 'access_token' => at.token,'id' => comment.id, 'diaspora_handle' => user.diaspora_handle }
      response.body.should == expected
    end

  end


  describe "#get_given_user_comment_list" do

    it "display given user status list" do
      user = FactoryGirl.create(:user)
	    scopes = Array  [ "comment_read", "comment_delete", "comment_write" ]
	    status= FactoryGirl.create(:status_message,:author=>user.person)
      comment = FactoryGirl.create(:comment,:post=>status,:author=>user.person)
      rt = FactoryGirl.create(:refresh_token, :user=> user, :scopes=> scopes)
      at   = FactoryGirl.create(:access_token, :refresh_token => rt)
	      
        expected={
          :author_id      => comment.author_id,
          :commentable_id => comment.commentable_id,
          :id 			      => comment.id,
          :likes_count    => comment.likes_count,
          :text          	=> comment.text
        }.to_json

      get 'get_given_user_comment_list' ,{ 'access_token' => at.token, 'diaspora_handle' => user.diaspora_handle }
      response.body.should include(expected)
    end
  end

  describe "#get_likes_count" do
    
    it "display given comment likes" do
      user = FactoryGirl.create(:user)
	    scopes = Array  [ "comment_read", "comment_delete", "comment_write" ]
	    status= FactoryGirl.create(:status_message,:author=>user.person)
      comment = FactoryGirl.create(:comment,:post=>status,:author=>user.person)
	    FactoryGirl.create(:like,:author=> user.person, :target=> comment)
      rt = FactoryGirl.create(:refresh_token, :user=> user, :scopes=> scopes)
      at   = FactoryGirl.create(:access_token, :refresh_token => rt)
	      expected={
	        :likes_count => "1"
        }.to_json

      get 'get_likes_count' ,{ 'access_token' => at.token,'id' => comment.id, 'diaspora_handle' => user.diaspora_handle }
      response.body.should include(expected)
    end
  end

  describe "#create_comment" do

    it "display ok status after creating new comment" do
      user = FactoryGirl.create(:user)
	    scopes = Array  [ "comment_read", "comment_delete", "comment_write" ]
	    status= FactoryGirl.create(:status_message,:author=>user.person)
	    text = "Test comment"
      rt = FactoryGirl.create(:refresh_token, :user=> user, :scopes=> scopes)
      at   = FactoryGirl.create(:access_token, :refresh_token => rt)
      get 'create_comment' ,{ 'access_token' => at.token, 'post_id' => status.id,'text' => text, 'diaspora_handle' => user.diaspora_handle }

	      expected={
          :id=> Comment.last.id,
          :guid => Comment.last.guid,
          :text => Comment.last.text
        }.to_json
 
      response.body.should include(text)
    end
  end

  describe "#delete_comment" do

    it "display ok status after deleting given comment" do
      user = FactoryGirl.create(:user)
	    scopes = Array  [ "comment_read", "comment_delete", "comment_write" ]
	    status= FactoryGirl.create(:status_message,:author=>user.person)
      comment = FactoryGirl.create(:comment,:post=>status,:author=>user.person)
      rt = FactoryGirl.create(:refresh_token, :user=> user, :scopes=> scopes)
      at   = FactoryGirl.create(:access_token, :refresh_token => rt)
      get 'delete_comment' ,{ 'access_token' => at.token,'id' => comment.id, 'diaspora_handle' => user.diaspora_handle }
      response.response_code.should == 200
    end
  end

end
