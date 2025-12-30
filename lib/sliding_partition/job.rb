
module SlidingPartition
  base = if defined?(::ApplicationJob)
           ::ApplicationJob
         elsif defined?(::ActiveJob) && defined?(::ActiveJob::Base)
           ::ActiveJob::Base
         else
           ::Object
         end

  class Job < base
    def perform(*)
      SlidingPartition.rotate!
    end
  end
end
