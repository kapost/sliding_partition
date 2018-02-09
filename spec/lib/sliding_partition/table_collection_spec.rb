# frozen_string_literal: true

require "spec_helper"
ENV["TZ"] = "UTC"

require "active_support/core_ext/integer/time"

RSpec.describe SlidingPartition::TableCollection do
  let(:definition) do
    instance_spy SlidingPartition::Definition,
                 inherited_table_name: "test_table",
                 time_column: :timestamp,
                 suffix: "%Y%m%d",
                 partition_interval: 1.month,
                 retention_interval: 6.months
  end

  subject { described_class.new(definition: definition, at_time: at_time) }

  shared_examples_for "a table generator" do
    it "generates the proper table collection" do
      expect(subject.map(&:table_name)).to match_array expected_tables
    end
  end

  describe "#each" do
    context "short month" do
      let(:expected_tables) do
        %w[test_table_20170801
           test_table_20170901
           test_table_20171001
           test_table_20171101
           test_table_20171201
           test_table_20180101
           test_table_20180201
           test_table_20180301]
      end

      context "start of month" do
        let(:at_time) { Time.new(2018, 2, 1, 0, 0).utc }

        it_behaves_like "a table generator"
      end

      context "near start of month" do
        let(:at_time) { Time.new(2018, 2, 3, 1, 3).utc }

        it_behaves_like "a table generator"
      end

      context "end of month" do
        let(:at_time) { Time.new(2018, 2, 28, 1, 3).utc }

        it_behaves_like "a table generator"
      end
    end

    context "long month" do
      let(:expected_tables) do
        %w[test_table_20170701
           test_table_20170801
           test_table_20170901
           test_table_20171001
           test_table_20171101
           test_table_20171201
           test_table_20180101
           test_table_20180201]
      end

      context "start of month" do
        let(:at_time) { Time.new(2018, 1, 1, 0, 0).utc }

        it_behaves_like "a table generator"
      end

      context "near start of month" do
        let(:at_time) { Time.new(2018, 1, 3, 10, 10).utc }

        it_behaves_like "a table generator"
      end

      context "end of month" do
        let(:at_time) { Time.new(2018, 1, 31, 1, 3).utc }

        it_behaves_like "a table generator"
      end
    end
  end
end
