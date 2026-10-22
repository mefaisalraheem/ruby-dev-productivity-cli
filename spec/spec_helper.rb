# frozen_string_literal: true

require "simplecov" if ENV["COVERAGE"]
SimpleCov.start if ENV["COVERAGE"]

require "tmpdir"
require "fileutils"
require_relative "../lib/devp"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    @tmpdir = Dir.mktmpdir("devp-test")
  end

  config.after(:each) do
    FileUtils.remove_entry(@tmpdir) if @tmpdir && Dir.exist?(@tmpdir)
  end
end