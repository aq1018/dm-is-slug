require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  describe 'DataMapper::Is::Slug' do
    
    class User
      include DataMapper::Resource

      property :id, Serial
      property :email, String
      has n, :posts
      
      def slug_for_email
        email.split("@").first
      end
      
      is :slug, :source => :slug_for_email, :size => 80, :permanent_slug => false
    end
    
    class Post
      include DataMapper::Resource

      property :id, Serial
      property :title, String, :size => 2000
      property :content, Text

      belongs_to :user

      is :slug, :source => :title
    end
    
    before :all do
      User.auto_migrate!(:default)
      Post.auto_migrate!(:default)

      @u1 = User.create(:email => "john@ekohe.com")
      @p1 = Post.create(:user => @u1, :title => "My first shinny blog post")
      @p2 = Post.create(:user => @u1, :title => "My second shinny blog post")
      @p3 = Post.create(:user => @u1, :title => "My third shinny blog post")

      @u2 = User.create(:email => "john@someotherplace.com")
      @p4 = Post.create(:user => @u2, :title => "My first Shinny blog post")
      @p5 = Post.create(:user => @u2, :title => "i heart merb and dm")
      @p6 = Post.create(:user => @u2, :title => "another productive day!!")
      @p7 = Post.create(:user => @u2, :title => "another productive day!!")
      @p8 = Post.create(:user => @u2, :title => "another productive day!!")
      @p9 = Post.create(:user => @u2, :title => "another productive day!!")
      @p10 = Post.create(:user => @u2, :title => "another productive day!!")
      @p11 = Post.create(:user => @u2, :title => "another productive day!!")
      @p12 = Post.create(:user => @u2, :title => "another productive day!!")
      @p13 = Post.create(:user => @u2, :title => "another productive day!!")
      @p14 = Post.create(:user => @u2, :title => "another productive day!!")
      @p15 = Post.create(:user => @u2, :title => "another productive day!!")
      @p16 = Post.create(:user => @u2, :title => "another productive day!!")
    end
    
    it "should generate slugs" do
      User.all.each do |u|
        u.slug.should_not be_nil
      end
      
      Post.all.each do |p|
        p.slug.should_not be_nil
      end            
    end
    
    it "should generate unique slugs" do
      @u1.slug.should_not == @u2.slug
      @p1.slug.should_not == @p4.slug
    end
    
    it "should generate correct slug for user" do
      @u1.slug.should == "john"
      @u2.slug.should == "john-2"
    end
    
    it "should generate correct slug for post" do
      @p1.slug.should == "my-first-shinny-blog-post"
      @p2.slug.should == "my-second-shinny-blog-post"
      @p3.slug.should == "my-third-shinny-blog-post"
      @p4.slug.should == "my-first-shinny-blog-post-2"
      @p5.slug.should == "i-heart-merb-and-dm"
      @p6.slug.should == "another-productive-day"
      @p7.slug.should == "another-productive-day-2"
      @p8.slug.should == "another-productive-day-3"
      @p9.slug.should == "another-productive-day-4"
      @p10.slug.should == "another-productive-day-5"
      @p11.slug.should == "another-productive-day-6"
      @p12.slug.should == "another-productive-day-7"
      @p13.slug.should == "another-productive-day-8"
      @p14.slug.should == "another-productive-day-9"
      @p15.slug.should == "another-productive-day-10"
      @p16.slug.should == "another-productive-day-11"
    end
    
    it "should update slug if :permanent_slug => :false is specified" do
      user = User.create(:email => "a_person@ekohe.com")
      user.slug.should == "a_person"
      
      user.should_not be_permanent_slug
      
      user.email = "changed@ekohe.com"
      user.should be_dirty
      user.save.should be_true
      user.slug.should == "changed"
      user.destroy
    end
    
    it "should not update slug if :permanent_slug => :true or not specified" do
      post = Post.create(:user => @u1, :title => "hello world!")
      post.slug.should ==  "hello-world"
      post.should be_permanent_slug
      post.title = "hello universe!"
      post.should be_dirty
      post.save.should be_true
      post.slug.should == "hello-world"
      post.destroy
    end
    
    it "should have the right size for properties" do
      user_slug_property = User.properties.detect{|p| p.name == :slug && p.type == String}
      user_slug_property.should_not be_nil
      user_slug_property.size.should == 80
      
      Post.properties.detect{|p| p.name == :title && p.type == String}.size.should == 2000
      post_slug_property = Post.properties.detect{|p| p.name == :slug && p.type == String}
      post_slug_property.should_not be_nil
      post_slug_property.size.should == 2000     
    end
    
    it "should find model with get method" do
      u = User.get("john")
      u.should_not be_nil
      u.should == @u1
      # test for collections
      @u1.posts.get("my-first-shinny-blog-post").should == @p1
    end
    
    it "should output slug with to_param method" do
      @u1.to_param.should == ["john"]
      @p1.to_param.should == ["my-first-shinny-blog-post"]
    end
    
  end
end
