require "spec_helper"

require "active_record"

RSpec.describe SlidingPartition::Job do

  JobMaster = Class.new(ActiveRecord::Base)

  JobEvent = Class.new(ActiveRecord::Base)

  let(:master_connection) do
    JobMaster.establish_connection connection_config.merge(database: "postgres", schema_search_path: "public")
    JobMaster.connection
  end

  let(:connection) do
    ActiveRecord::Base.establish_connection(connection_config)
    ActiveRecord::Base.connection
  end

  let(:connection_config) do
    {
      adapter: "postgresql",
      database: "sliding_partition_test"
    }
  end

  before do
    begin
      master_connection.create_database("sliding_partition_test")
    rescue ActiveRecord::StatementInvalid => error
      if /database .* already exists/ === error.message
        nil
      else
        raise
      end
    end

      connection.execute <<-SQL
      CREATE TABLE IF NOT EXISTS job_events (
        id         serial    PRIMARY KEY,
        name       varchar   NOT NULL,
        event_at   timestamp NOT NULL,

        created_at timestamp NOT NULL DEFAULT NOW(),
        updated_at timestamp NOT NULL DEFAULT NOW()
      );

      CREATE INDEX ON job_events (event_at, name)
    SQL
  end

  after do
    connection.tables.sort.reverse.each { |t| connection.drop_table(t) }
    connection.disconnect!
    master_connection.drop_database("sliding_partition_test")
  end

  describe "job execution" do
    before do
      # clear any global definitions so rotate! only affects our test model
      SlidingPartition.parititions.clear

      SlidingPartition.define(JobEvent) do |partition|
        partition.time_column        = :event_at
        partition.suffix             = "%Y%m%d"
        partition.partition_interval = 1.month
        partition.retention_interval = 6.months
      end
    end

    it "responds to perform and creates partition tables when run" do
      # ensure no partition tables exist initially
      expect(connection.tables.any? { |t| t.start_with?("job_events_") }).to be false

      # run the job; it should cause partition creation via SlidingPartition.rotate!
      SlidingPartition::Job.new.perform

      tables = connection.tables

      expect(tables.any? { |t| t.start_with?("job_events_") }).to be true
    end
  end
end
