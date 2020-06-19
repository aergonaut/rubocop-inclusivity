# frozen_string_literal: true

RSpec.describe RuboCop::Inclusivity do
  it "has a version number" do
    expected_version = File.read(File.expand_path("../../VERSION", __dir__))
    expect(RuboCop::Inclusivity::VERSION).to eq(expected_version)
  end
end
