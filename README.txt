= dm-is-slug

DataMapper plugin for creating and slugs(permalinks).

== Installation

NOTE: You no longer need to download dm-more source code in order to install
this.

All you need to do is:

$ sudo rake install

Remember to require it in your app's init.rb

dependency 'dm-is-slug'

== Getting started

Lets say we have a post-class, and we want to generate permalinks or slugs for all posts.

class Post
  include DataMapper::Resource

  property :id, Serial
  property :title, String
  property :content, String

  # here we define that it should have a slug that uses title as the permalink
  # it will generate an extra slug property of String type, with the same size as title
  is :slug, :source => :title
end

Let's Say we need to define a permalink based on a method instead of a property.

class User
  include DataMapper::Resource

  property :id, Serial
  property :email, String
  property :password, String
  
  # we only want to strip out the domain name 
  # and use only the email account name as the permalink
  def slug_for_email
    email.split("@").first
  end
  
  # here we define that it should have a slug that uses title as the permalink
  # it will generate an extra slug property of String type, with the same size as title
  is :slug, :source => :slug_for_email, :size => 255
end

You can now find objects by slug like this:

 post = Post.first(:slug => "your_slug")
