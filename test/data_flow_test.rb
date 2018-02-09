require File.expand_path('test/test_helper')

class ModelTest < ActiveModel::TestCase

  class StepOne
    def self.perform(data)
      yield({ :text => data['text'] })
    end
  end

  class StepTwo
    def self.perform(data)
      yield({ :id => 'StepTwo', :text => data['text'].downcase })
    end
  end

  class StepThree
    def self.perform(data)
      yield({ :id => 'StepThree', :text => data['text'].upcase })
    end
  end

  class LastStep
    def self.perform(data)
      Related.redis.set("DataFlowResult#{data['id']}", data['text'])
    end
  end

  def setup
    Related.flushall
  end

  def teardown
    Related.clear_data_flows
  end

  def test_defining_a_data_flow
    Related.data_flow :like, StepOne => { StepTwo => nil }
    assert_equal({ :like => [{ StepOne => { StepTwo => nil } }] }, Related.data_flows)
  end

  def test_executing_a_simple_data_flow
    Related.data_flow :like, StepOne => { LastStep => nil }
    Related::Relationship.create(:like, Related::Node.create, Related::Node.create, :text => 'Hello world!')
    assert_equal 'Hello world!', Related.redis.get('DataFlowResult')
  end

  def test_executing_a_complicated_data_flow
    Related.data_flow :like, StepOne => { StepTwo => { LastStep => nil }, StepThree => { LastStep => nil } }
    Related::Relationship.create(:like, Related::Node.create, Related::Node.create, :text => 'Hello world!')
    assert_equal 'hello world!', Related.redis.get('DataFlowResultStepTwo')
    assert_equal 'HELLO WORLD!', Related.redis.get('DataFlowResultStepThree')
  end

end
