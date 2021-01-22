# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Inclusivity::Race, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    {
      "Offenses" => {
        "whitelist" => ["allowlist", "passlist", "permitlist"],
        "blacklist" => ["banlist", "blocklist", "denylist"],
        "master" => ["primary", "main"],
        "slave" => ["secondary", "replica"]
      },
      "Allowlist" => {
        "mastercard": {
          "partial" => false
        },
        "blob/master": {
          "partial" => true
        }
      }
    }
  end

  describe "allowlist" do
    describe "partial" do
      it "does not add offenses to comments" do
        expect_no_offenses(<<~RUBY)
          # blob/master
        RUBY

        expect_no_offenses(<<~RUBY)
          # https://github.com/aergonaut/rubocop-inclusivity/blob/master/foo/bar.rb
        RUBY
      end

      it "does not add offenses to code" do
        expect_no_offenses(<<~RUBY)
          x = "blob/master"
        RUBY

        expect_no_offenses(<<~RUBY)
          x = "https://github.com/aergonaut/rubocop-inclusivity/blob/master/foo/bar.rb"
        RUBY
      end

      it "is case-insensitive" do
        expect_no_offenses(<<~RUBY)
          x = "BLOB/MASTER"
        RUBY
      end
    end

    describe "non-partial" do
      describe "comments" do
        it "does not add offenses to full matches" do
          expect_no_offenses(<<~RUBY)
            # providers like mastercard
          RUBY
        end

        it "adds offenses to patial matches" do
          expect_offense(<<~RUBY)
            # dealers who are mastercarders
                              ^^^^^^^^^^^^^ `mastercarders` may be insensitive. Consider alternatives: primarycarders, maincarders
          RUBY
        end
      end

      describe "code" do
        it "does not add offenses to full matches" do
          expect_no_offenses(<<~RUBY)
            providers << "mastercard"
          RUBY
        end

        it "does not add offenses to patial matches" do
          expect_offense(<<~RUBY)
            dealers << "mastercarder"
                       ^^^^^^^^^^^^^^ `mastercarder` may be insensitive. Consider alternatives: primarycarder, maincarder
          RUBY
        end
      end

      it "is case-insensitive" do
        expect_no_offenses(<<~RUBY)
          providers << :MASTERCARD
        RUBY
      end
    end
  end

  describe "checks" do
    describe "comments" do
      specify "plain" do
        expect_no_offenses(<<~RUBY)
          # see more about foo here
        RUBY

        expect_offense(<<~RUBY)
          # see more about blacklist here
                           ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
        RUBY

        expect_correction(<<~RUBY)
          # see more about banlist here
        RUBY
      end

      specify "in the middle of the doc" do
        expect_no_offenses(%(
          class Foo
            def bar
            end

            # see more about foo here
            def baz
            end
          end
        ))

        expect_offense(%(
          class Foo
            def bar
            end

            # see more about blacklist here
                             ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
            def baz
            end
          end
        ))
      end
    end

    specify "variables" do
      expect_no_offenses(<<~RUBY)
        banlist = 1
      RUBY

      expect_offense(<<~RUBY)
        blacklist = 1
        ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
      RUBY

      expect_correction(<<~RUBY)
        banlist = 1
      RUBY
    end

    describe "constants" do
      specify "simple" do
        expect_no_offenses(<<~RUBY)
          BANLIST = ["foo", "bar"]
        RUBY

        expect_offense(<<~RUBY)
          BLACKLIST = ["foo", "bar"]
          ^^^^^^^^^ `BLACKLIST` may be insensitive. Consider alternatives: BANLIST, BLOCKLIST, DENYLIST
        RUBY

        expect_correction(<<~RUBY)
          BANLIST = ["foo", "bar"]
        RUBY
      end

      specify "multiword" do
        expect_no_offenses(<<~RUBY)
          FOO_BANLIST = ["foo", "bar"]
        RUBY

        expect_offense(<<~RUBY)
          FOO_BLACKLIST = ["foo", "bar"]
          ^^^^^^^^^^^^^ `FOO_BLACKLIST` may be insensitive. Consider alternatives: FOO_BANLIST, FOO_BLOCKLIST, FOO_DENYLIST
        RUBY

        expect_correction(<<~RUBY)
          FOO_BANLIST = ["foo", "bar"]
        RUBY
      end
    end

    specify "symbols" do
      expect_no_offenses(<<~RUBY)
        :bar
      RUBY

      expect_offense(<<~RUBY)
        :blacklist
        ^^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
      RUBY

      expect_correction(<<~RUBY)
        :banlist
      RUBY
    end

    describe "strings" do
      specify "single" do
        expect_no_offenses(<<~RUBY)
          'bar'
        RUBY

        expect_offense(<<~RUBY)
          'blacklist'
          ^^^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
        RUBY

        expect_correction(<<~RUBY)
          'banlist'
        RUBY
      end

      specify "double" do
        expect_no_offenses(<<~RUBY)
          "bar"
        RUBY

        expect_offense(<<~RUBY)
          "blacklist"
          ^^^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
        RUBY

        expect_correction(<<~RUBY)
          "banlist"
        RUBY
      end

      specify "interpolated" do
        expect_no_offenses(%q(
          "foo#{bar}"
        ))

        expect_offense(%q(
          "blacklist#{bar}"
           ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
        ))

        expect_correction(%q(
          "banlist#{bar}"
        ))
      end
    end

    describe "arrays" do
      specify "single" do
        expect_no_offenses(<<~RUBY)
          foo = [bar]
        RUBY

        expect_offense(<<~RUBY)
          foo = [blacklist]
                 ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
        RUBY

        expect_correction(<<~RUBY)
          foo = [banlist]
        RUBY
      end

      specify "multiple" do
        expect_no_offenses(<<~RUBY)
          foo = [bar, buz]
        RUBY

        expect_offense(<<~RUBY)
          foo = [blacklist, whitelist]
                            ^^^^^^^^^ `whitelist` may be insensitive. Consider alternatives: allowlist, passlist, permitlist
                 ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
        RUBY

        expect_correction(<<~RUBY)
          foo = [banlist, allowlist]
        RUBY
      end

      specify "multiline" do
        expect_no_offenses(<<~RUBY)
          foo = [
            bar,
            buz,
          ]
        RUBY

        expect_offense(<<~RUBY)
          foo = [
            blacklist,
            ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
            whitelist,
            ^^^^^^^^^ `whitelist` may be insensitive. Consider alternatives: allowlist, passlist, permitlist
          ]
        RUBY

        expect_correction(<<~RUBY)
          foo = [
            banlist,
            allowlist,
          ]
        RUBY
      end
    end

    describe "classes" do
      specify "declarations" do
        expect_no_offenses(<<~RUBY)
          class Foo
          end
        RUBY

        expect_offense(<<~RUBY)
          class Blacklist
                ^^^^^^^^^ `Blacklist` may be insensitive. Consider alternatives: Banlist, Blocklist, Denylist
          end
        RUBY

        expect_correction(<<~RUBY)
          class Banlist
          end
        RUBY
      end

      specify "nested" do
        expect_no_offenses(<<~RUBY)
          Foo::Bar
        RUBY

        expect_offense(<<~RUBY)
          Foo::Blacklist
               ^^^^^^^^^ `Blacklist` may be insensitive. Consider alternatives: Banlist, Blocklist, Denylist
        RUBY

        expect_correction(<<~RUBY)
          Foo::Banlist
        RUBY
      end

      specify "singleton calls" do
        expect_no_offenses(<<~RUBY)
          Foo.bar
        RUBY

        expect_offense(<<~RUBY)
          Foo.blacklist
              ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
        RUBY

        expect_correction(<<~RUBY)
          Foo.banlist
        RUBY
      end
    end

    describe "methods" do
      describe "invocations" do
        specify "simple/variables" do
          expect_no_offenses(<<~RUBY)
            foo
          RUBY

          expect_offense(<<~RUBY)
            blacklist
            ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          RUBY

          expect_correction(<<~RUBY)
            banlist
          RUBY
        end

        specify "multiword" do
          expect_no_offenses(<<~RUBY)
            foo_bar
          RUBY

          expect_offense(<<~RUBY)
            foo_blacklist
            ^^^^^^^^^^^^^ `foo_blacklist` may be insensitive. Consider alternatives: foo_banlist, foo_blocklist, foo_denylist
          RUBY

          expect_correction(<<~RUBY)
            foo_banlist
          RUBY
        end

        specify "camelized" do
          expect_no_offenses(<<~RUBY)
            fooBar
          RUBY

          expect_offense(<<~RUBY)
            fooBlacklist
            ^^^^^^^^^^^^ `fooBlacklist` may be insensitive. Consider alternatives: fooBanlist, fooBlocklist, fooDenylist
          RUBY

          expect_correction(<<~RUBY)
            fooBanlist
          RUBY
        end

        specify "nested" do
          expect_no_offenses(<<~RUBY)
            foo.bar
          RUBY

          expect_offense(<<~RUBY)
            foo.blacklist.whitelist
                          ^^^^^^^^^ `whitelist` may be insensitive. Consider alternatives: allowlist, passlist, permitlist
                ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          RUBY

          expect_correction(<<~RUBY)
            foo.banlist.allowlist
          RUBY
        end

        specify "singleton" do
          expect_no_offenses(<<~RUBY)
            Foo.bar
          RUBY

          expect_offense(<<~RUBY)
            Foo.blacklist.whitelist
                          ^^^^^^^^^ `whitelist` may be insensitive. Consider alternatives: allowlist, passlist, permitlist
                ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          RUBY

          expect_correction(<<~RUBY)
            Foo.banlist.allowlist
          RUBY
        end
      end

      specify "name" do
        expect_no_offenses(<<~RUBY)
          def foo
          end
        RUBY

        expect_offense(<<~RUBY)
          def blacklist
              ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          end
        RUBY

        expect_correction(<<~RUBY)
          def banlist
          end
        RUBY
      end

      specify "args" do
        expect_no_offenses(<<~RUBY)
          def foo(bar)
          end
        RUBY

        expect_offense(<<~RUBY)
          def foo(blacklist)
                  ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo(banlist)
          end
        RUBY
      end

      specify "arg defaults" do
        expect_no_offenses(<<~RUBY)
          def foo(bar = buz)
          end
        RUBY

        expect_offense(<<~RUBY)
          def foo(bar = blacklist)
                        ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo(bar = banlist)
          end
        RUBY
      end

      specify "optargs" do
        expect_no_offenses(<<~RUBY)
          def foo(bar = nil)
          end
        RUBY

        expect_offense(<<~RUBY)
          def foo(blacklist = nil)
                  ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo(banlist = nil)
          end
        RUBY
      end

      specify "restargs" do
        expect_no_offenses(<<~RUBY)
          def foo(bar, buz = nil)
          end
        RUBY

        expect_offense(<<~RUBY)
          def foo(bar, *blacklist)
                        ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo(bar, *banlist)
          end
        RUBY
      end

      specify "kwarg" do
        expect_no_offenses(<<~RUBY)
          def foo(buz:)
          end
        RUBY

        expect_offense(<<~RUBY)
          def foo(blacklist:)
                  ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo(banlist:)
          end
        RUBY
      end

      specify "kwoptarg" do
        expect_no_offenses(<<~RUBY)
          def foo(buz: nil)
          end
        RUBY

        expect_offense(<<~RUBY)
          def foo(blacklist: nil)
                  ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo(banlist: nil)
          end
        RUBY
      end

      specify "kwrestarg" do
        expect_no_offenses(<<~RUBY)
          def foo(**buz)
          end
        RUBY

        expect_offense(<<~RUBY)
          def foo(**blacklist)
                    ^^^^^^^^^ `blacklist` may be insensitive. Consider alternatives: banlist, blocklist, denylist
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo(**banlist)
          end
        RUBY
      end
    end
  end
end
