require File.expand_path('test/test_helper')

class ActiveModelTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class Like < Related::Entity
    validates_numericality_of :how_much, :allow_nil => true

    before_save :before_save_callback
    after_save :after_save_callback
    before_create :before_create_callback
    after_create :after_create_callback
    before_update :before_update_callback
    after_update :after_update_callback
    before_destroy :before_destroy_callback
    after_destroy :after_destroy_callback

    attr_reader :before_save_was_called
    attr_reader :after_save_was_called
    attr_reader :before_create_was_called
    attr_reader :after_create_was_called
    attr_reader :before_update_was_called
    attr_reader :after_update_was_called
    attr_reader :before_destroy_was_called
    attr_reader :after_destroy_was_called

    def before_save_callback
      @before_save_was_called = true
    end
    def after_save_callback
      @after_save_was_called = true
    end
    def before_create_callback
      @before_create_was_called = true
    end
    def after_create_callback
      @after_create_was_called = true
    end
    def before_update_callback
      @before_update_was_called = true
    end
    def after_update_callback
      @after_update_was_called = true
    end
    def before_destroy_callback
      @before_destroy_was_called = true
    end
    def after_destroy_callback
      @after_destroy_was_called = true
    end
  end

  def setup
    Related.flushall
    @model = Related::Entity.new
  end

  def test_attributes_has_id
    node = Related::Entity.create
    assert_equal node.id, node.attributes['id']
  end

  def test_can_return_json
    node = Related::Entity.create(:name => 'test')
    json = { :node => node }.to_json
    json = JSON.parse(json)
    assert_equal node.id, json['node']['id']
    assert_equal node.name, json['node']['name']
  end

  def test_query_can_return_json
    node1 = Related::Node.create(:name => 'node1')
    node2 = Related::Node.create(:name => 'node2')
    Related::Relationship.create(:friends, node1, node2)
    json = { :nodes => node1.outgoing(:friends) }.to_json
    json = JSON.parse(json)
    assert_equal node2.id, json['nodes'][0]['id']
    assert_equal node2.name, json['nodes'][0]['name']
  end

  def test_validations
    like = Like.new(:how_much => 'not much')
    assert_equal false, like.valid?
    assert_equal [:how_much], like.errors.messages.keys
    assert_raises Related::ValidationsFailed do
      like.save
    end
    begin
      like.save
    rescue Related::ValidationsFailed => e
      assert_equal like, e.object
    end
    like.how_much = 1.0
    assert_equal true, like.valid?
    assert_nothing_raised do
      like.save
    end
  end

  def test_save_callbacks
    like = Like.new
    assert_equal nil, like.before_save_was_called
    assert_equal nil, like.after_save_was_called
    like.save
    assert_equal true, like.before_save_was_called
    assert_equal true, like.after_save_was_called
  end

  def test_create_callbacks
    like = Like.new
    assert_equal nil, like.before_create_was_called
    assert_equal nil, like.after_create_was_called
    like.save
    assert_equal true, like.before_create_was_called
    assert_equal true, like.after_create_was_called
  end

  def test_update_callbacks
    like = Like.new
    like.save
    assert_equal nil, like.before_update_was_called
    assert_equal nil, like.after_update_was_called
    like.save
    assert_equal true, like.before_update_was_called
    assert_equal true, like.after_update_was_called
  end

  def test_create_callbacks
    like = Like.new
    assert_equal nil, like.before_destroy_was_called
    assert_equal nil, like.after_destroy_was_called
    like.destroy
    assert_equal true, like.before_destroy_was_called
    assert_equal true, like.after_destroy_was_called
  end

end
