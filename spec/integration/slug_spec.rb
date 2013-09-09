# encoding: utf-8

require 'spec_helper'


describe DataMapper::Is::Slug do

  before :all do
    class ::User
      include DataMapper::Resource

      property :id, Serial
      property :email, String
      has n, :posts
      has n, :todos

      def slug_for_email
        email.split("@").first
      end

      is :slug, :source => :slug_for_email, :length => 80, :permanent_slug => false
    end

    class ::Post
      include DataMapper::Resource

      property :id, Serial
      property :title, String, :length => 30
      property :content, Text

      belongs_to :user

      is :slug, :source => :title
    end

    class ::Todo
      include DataMapper::Resource
      property :id, Serial
      property :title, String

      belongs_to :user
    end

    class ::Task
      include DataMapper::Resource
      property :id, Serial
      property :title, String
      property :description, String
      property :category, String

      is :slug, :source => :title, :scope => :category
    end

    class ::SlugKey
      include DataMapper::Resource
      property :title, String

      is :slug, :source => :title, :key => true
    end

    class ::Post2
      include DataMapper::Resource

      property :id, Serial
      property :title, String, :length => 30
      property :content, Text

      is :slug, :source => :title, :permanent_slug => false
    end
  end

  supported_by :in_memory, :yaml, :sqlite, :mysql, :postgres do

    before :all do
      DataMapper.repository do
        puts ">>> #{DataMapper.repository.adapter.inspect}"
        DataMapper.logger.set_log STDOUT, :debug, ' ~ ', true
        DataMapper.logger << 'boo!'
        @u1 = User.create(:email => "john@ekohe.com")
        @p1 = Post.create(:user => @u1, :title => "My first shinny blog post")
        @p2 = Post.create(:user => @u1, :title => "My second shinny blog post")
        @p3 = Post.create(:user => @u1, :title => "My third shinny blog post")

        @u2 = User.create(:email => "john@someotherplace.com")
        @p4 = Post.create(:user => @u2, :title => "My first Shinny blog post")
        @p5 = Post.create(:user => @u2, :title => "i heart merb and dm")
        @p6 = Post.create(:user => @u2, :title => "A fancy café")
        @p7 = Post.create(:user => @u2, :title => "你好")

        (1..10).each do |i|
          instance_variable_set "@p1_#{i}".to_sym, Post.create(:user => @u2, :title => "another productive day!!")
        end
        (1..10).each do |i|
          instance_variable_set "@p2_#{i}".to_sym, Post.create(:user => @u2, :title => "DM tricks")
        end

        @sk = SlugKey.create(:title => 'slug key')

        @post1 = Post.create :user => @u1, :title => 'a' * Post.slug_property.length
        @post2 = Post.create :user => @u1, :title => 'a' * Post.slug_property.length
      end
    end

    it "should raise error if :source option is not specified" do
      lambda {
        class BadUsage
          include DataMapper::Resource

          property :id, Serial

          is :slug, {}
        end
      }.should raise_error(DataMapper::Is::Slug::InvalidSlugSourceError)
    end

    it "should display obsolete warning if :size option is used" do
      module M
        class Thingy
        end
      end
      M::Thingy.stub!(:warn)
      M::Thingy.should_receive(:warn).with("Slug with :size option is deprecated, use :length instead")

      lambda {
        class M::Thingy
          include DataMapper::Resource
          property :id, Serial
          property :title, String

          is :slug, :source => :title, :size => 20
        end
      }.should_not raise_error

      M.const_set 'Thingy', nil
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

      @p1_1.slug.should == "another-productive-day"
      (2..10).each do |i|
        instance_variable_get("@p1_#{i}".to_sym).slug.should == "another-productive-day-#{i}"
      end

      @p2_1.slug.should == 'dm-tricks'
      (2..10).each do |i|
        instance_variable_get("@p2_#{i}".to_sym).slug.should == "dm-tricks-#{i}"
      end
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
      user_slug_property = User.properties[:slug]
      user_slug_property.should_not be_nil
      user_slug_property.should be_an_instance_of(DataMapper::Property::String)
      user_slug_property.length.should == 80

      post_title_property = Post.properties[:title]
      post_title_property.should be_an_instance_of(DataMapper::Property::String)
      post_title_property.length.should == 30

      post_slug_property = Post.properties[:slug]
      post_slug_property.should be_an_instance_of(DataMapper::Property::String)
      post_slug_property.should_not be_nil
      post_slug_property.length.should == 30
    end

    it "should output slug with to_param method" do
      @u1.to_param.should == ["john"]
      @p1.to_param.should == ["my-first-shinny-blog-post"]
    end

    it "should find model using get method using id" do
      u = User.get(@u1.id)
      u.should_not be_nil
      u.should == @u1
    end

    it "should find model using get method using id with non-slug models" do
      todo = Todo.create(:user => @u1, :title => "blabla")
      todo.should_not be_nil

      Todo.get(todo.id).should == todo
      @u1.todos.get(todo.id).should == todo
    end

    it 'should unidecode latin characters from the slug' do
      @p6.slug.should == 'a-fancy-cafe'
    end

    it 'should unidecode chinese characters from the slug' do
      @p7.slug.should == 'ni-hao'
    end

    it 'should have slug_property on instance' do
      @p1.slug_property.should == @p1.class.properties.detect{|p| p.name == :slug}
    end

    it 'should properly increment slug suffix' do
      @p2_10.slug.should == 'dm-tricks-10'
    end

    it 'should work with key on slug and validations' do
      @sk.title.should == 'slug key'
      @sk.slug.should == 'slug-key'
    end

    it 'should have slug no longer than slug_property.length' do
      @post1.slug.length.should == @post1.slug_property.length
    end

    it 'should have suffixed slug no longer than slug_property.length' do
      @post2.slug.length.should == @post2.class.slug_property.length
    end

    it 'should generate right slug for long sources' do
      @post1.slug.should == 'a' * @post1.class.slug_property.length
      @post2.slug.should == ('a' * (@post2.class.slug_property.length - 2) + '-2')
    end

    describe 'editing' do
      before :each do
        Post2.all.destroy!
        @post = Post2.create :title => 'The Post', :content => 'The content.'
      end

      it 'should not change slug if source is not changed' do
        @post.update(:content => 'The other content.').should be_true
        @post.reload
        @post.slug.should == 'the-post'
      end

      it 'should change slug if source is changed' do
        @post.update :title => 'The Other Post'
        post = Post2.first
        post.slug.should == 'the-other-post'
      end
    end

    describe 'scoping' do
      before :each do
        Task.all.destroy!
      end

      it 'should allow duplicate slugs within different scopes' do
        t1 = Task.create :category => 'programming', :title => 'fix'
        t1.slug.should == 'fix'

        t2 = Task.create :category => 'plumbing', :title => 'fix'
        t2.slug.should == 'fix'
      end

      it 'should not allow dupliate slugs within same scope' do
        t1 = Task.create :category => 'programming', :title => 'fix'
        t1.slug.should == 'fix'

        t2 = Task.create :category => 'programming', :title => 'fix'
        t2.slug.should == 'fix-2'
      end

      it 'should recalculate slug upon change of scope' do
        t1 = Task.create :category => 'programming', :title => 'fix'
        t1.slug.should == 'fix'

        t2 = Task.create :category => 'plumbing', :title => 'fix'
        t2.slug.should == 'fix'

        t2.category = 'programming'
        t2.save
        t2.slug.should == 'fix-2'
      end

      it 'should keep slug if scope did not change' do
        t1 = Task.create :category => 'programming', :title => 'fix'
        t1.slug.should == 'fix'

        t2 = Task.create :category => 'plumbing', :title => 'fix'
        t2.slug.should == 'fix'

        t2.description = 'copper pipes are good'
        t2.save
        t2.slug.should == 'fix'
      end
    end
  end
end
