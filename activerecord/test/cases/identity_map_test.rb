require "cases/helper"
require 'models/developer'
require 'models/project'
require 'models/company'
require 'models/topic'
require 'models/reply'
require 'models/computer'
require 'models/customer'
require 'models/order'
require 'models/post'
require 'models/author'
require 'models/tag'
require 'models/tagging'
require 'models/comment'
require 'models/sponsor'
require 'models/member'
require 'models/essay'
require 'models/subscriber'

class IdentityMapTest < ActiveRecord::TestCase
  fixtures :accounts, :companies, :developers, :projects, :topics,
    :developers_projects, :computers, :authors, :author_addresses,
    :posts, :tags, :taggings, :comments, :subscribers

  def test_find_id
    assert_same(
      Client.find(3),
      Client.find(3)
    )
  end

  def test_find_pkey
    assert_same(
      Subscriber.find('swistak'),
      Subscriber.find('swistak')
    )
  end

  def test_find_by_id
    assert_same(
      Client.find_by_id(3),
      Client.find_by_id(3)
    )
  end

  def test_find_by_pkey
    assert_same(
      Subscriber.find_by_nick('swistak'),
      Subscriber.find_by_nick('swistak')
    )
  end
  
  def test_find_first_id
    assert_same(
      Client.find(:first, :conditions => {:id => 1}),
      Client.find(:first, :conditions => {:id => 1})
    )
  end

  def test_find_first_pkey
    assert_same(
      Subscriber.find(:first, :conditions => {:nick => 'swistak'}),
      Subscriber.find(:first, :conditions => {:nick => 'swistak'})
    )
  end

  def test_im_with_polymorphic_has_many_going_through_join_model_with_custom_select_and_joins
    tag = posts(:welcome).tags.first
    tag_with_joins_and_select = posts(:welcome).tags.add_joins_and_select.first
    assert_same(tag, tag_with_joins_and_select)
    assert_nothing_raised(NoMethodError, "Joins/select was not loaded") { tag.author_id }
  end

  def test_find_with_preloaded_associations
    assert_queries(2) do
      posts = Post.preload(:comments)
      assert posts.first.comments.first
    end

    # With IM we'll retrieve post object from previous query, it'll have comments
    # already preloaded from first call
    assert_queries(1) do
      posts = Post.preload(:comments).to_a
      assert posts.first.comments.first
    end

    assert_queries(2) do
      posts = Post.preload(:author)
      assert posts.first.author
    end

    # With IM we'll retrieve post object from previous query, it'll have comments
    # already preloaded from first call
    assert_queries(1) do
      posts = Post.preload(:author).to_a
      assert posts.first.author
    end

    assert_queries(1) do
      posts = Post.preload(:author, :comments).to_a
      assert posts.first.author
      assert posts.first.comments.first
    end
  end

  def test_find_with_included_associations
    assert_queries(2) do
      posts = Post.includes(:comments)
      assert posts.first.comments.first
    end

    assert_queries(1) do
      posts = Post.scoped.includes(:comments)
      assert posts.first.comments.first
    end

    assert_queries(2) do
      posts = Post.includes(:author)
      assert posts.first.author
    end

    assert_queries(1) do
      posts = Post.includes(:author, :comments).to_a
      assert posts.first.author
      assert posts.first.comments.first
    end
  end

  def test_eager_loading_with_conditions_on_joined_table_preloads
    posts = assert_queries(2) do
      Post.find(:all, :select => 'distinct posts.*', :include => :author, :joins => [:comments], :conditions => "comments.body like 'Thank you%'", :order => 'posts.id')
    end
    assert_equal [posts(:welcome)], posts
    assert_equal authors(:david), assert_no_queries { posts[0].author}

    posts = assert_queries(1) do
      Post.find(:all, :select => 'distinct posts.*', :include => :author, :joins => [:comments], :conditions => "comments.body like 'Thank you%'", :order => 'posts.id')
    end
    assert_equal [posts(:welcome)], posts
    assert_equal authors(:david), assert_no_queries { posts[0].author}

    posts = assert_queries(1) do
      Post.find(:all, :include => :author, :joins => {:taggings => :tag}, :conditions => "tags.name = 'General'", :order => 'posts.id')
    end
    assert_equal posts(:welcome, :thinking), posts

    posts = assert_queries(1) do
      Post.find(:all, :include => :author, :joins => {:taggings => {:tag => :taggings}}, :conditions => "taggings_tags.super_tag_id=2", :order => 'posts.id')
    end
    assert_equal posts(:welcome, :thinking), posts
  end

  def test_eager_loading_with_conditions_on_string_joined_table_preloads
    posts = assert_queries(2) do
      Post.find(:all, :select => 'distinct posts.*', :include => :author, :joins => "INNER JOIN comments on comments.post_id = posts.id", :conditions => "comments.body like 'Thank you%'", :order => 'posts.id')
    end
    assert_equal [posts(:welcome)], posts
    assert_equal authors(:david), assert_no_queries { posts[0].author}

    posts = assert_queries(1) do
      Post.find(:all, :select => 'distinct posts.*', :include => :author, :joins => ["INNER JOIN comments on comments.post_id = posts.id"], :conditions => "comments.body like 'Thank you%'", :order => 'posts.id')
    end
    assert_equal [posts(:welcome)], posts
    assert_equal authors(:david), assert_no_queries { posts[0].author}
  end
end
