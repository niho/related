module Related
  module DataFlow

    def data_flow(name, steps)
      @data_flows ||= {}
      @data_flows[name.to_sym] ||= []
      @data_flows[name.to_sym] << steps
    end

    def data_flows
      @data_flows
    end

    def clear_data_flows
      @data_flows = {}
    end

    def execute_data_flow(name_or_flow, data)
      @data_flows ||= {}
      if name_or_flow.is_a?(Hash)
        enqueue_flow(name_or_flow, data)
      else
        flows = @data_flows[name_or_flow.to_sym] || []
        flows.each do |flow|
          enqueue_flow(flow, data)
        end
      end
    end

    class DataFlowJob
      @queue = :related
      def self.perform(flow, data)
        flow.keys.each do |key|
          step = key.constantize
          step.perform(data) do |result|
            if flow[key]
              Related.execute_data_flow(flow[key], result)
            end
          end
        end
      end
    end

  protected

    def enqueue_flow(flow, data)
      if defined?(Resque)
        Resque.enqueue(DataFlowJob, flow, data)
      else
        DataFlowJob.perform(JSON.parse(flow.to_json), JSON.parse(data.to_json))
      end
    end

  end
end
