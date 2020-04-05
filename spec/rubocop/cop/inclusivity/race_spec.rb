# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Inclusivity::Race, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    {
      "Offenses" => {
        "whitelist" => ["allowlist", "passlist", "permitlist"],
        "blacklist" => ["banlist, blocklist, denylist"]
      }
    }
  end

  # TODO: Write test code
  #
  # For example
  it "registers an offense when using insensitive language" do
    expect_offense(<<~RUBY)
      blacklist = 1
      ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
    RUBY
  end

  it "does not register an offense when using preferred language" do
    expect_no_offenses(<<~RUBY)
      banlist = 1
    RUBY
  end
end
