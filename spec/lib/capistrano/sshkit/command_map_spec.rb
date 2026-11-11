require "spec_helper"

module Capistrano
  module SSHKitExt
    describe CommandMapExt do
      let(:command_map) { SSHKit::CommandMap.new }

      describe "when a command prefix is registered" do
        before do
          command_map.prefix[:rake] << "rvm 3.3.0 do"
        end

        it "prepends the prefix to the bare command by default" do
          expect(command_map[:rake]).to eq("rvm 3.3.0 do rake")
        end

        it "prepends the prefix to an explicit command mapping" do
          command_map[:rake] = "with-bitwarden bundle exec rake"
          expect(command_map[:rake])
            .to eq("rvm 3.3.0 do with-bitwarden bundle exec rake")
        end

        it "prepends the prefix to a callable command mapping" do
          command_map[:rake] = -> { "with-bitwarden bundle exec rake" }
          expect(command_map[:rake])
            .to eq("rvm 3.3.0 do with-bitwarden bundle exec rake")
        end

        it "keeps the bare command for builtins like test and if" do
          command_map.prefix[:test] << "rvm 3.3.0 do"
          expect(command_map[:test]).to eq("rvm 3.3.0 do test")
        end
      end

      describe "when no prefix is registered" do
        it "returns the default /usr/bin/env mapping" do
          expect(command_map[:rake]).to eq("/usr/bin/env rake")
        end

        it "returns an explicit command mapping" do
          command_map[:rake] = "bundle exec rake"
          expect(command_map[:rake]).to eq("bundle exec rake")
        end

        it "returns a callable command mapping" do
          command_map[:rake] = -> { "bundle exec rake" }
          expect(command_map[:rake]).to eq("bundle exec rake")
        end
      end

      describe "when the map is initialized with a hash" do
        it "prepends the prefix to mappings passed via the constructor" do
          map = SSHKit::CommandMap.new(rake: "bundle exec rake")
          map.prefix[:rake] << "rvm 3.3.0 do"
          expect(map[:rake]).to eq("rvm 3.3.0 do bundle exec rake")
        end

        it "falls back to the bare command when a constructor mapping cannot be found" do
          map = SSHKit::CommandMap.new("rake" => "bundle exec rake")
          map.prefix[:rake] << "rvm 3.3.0 do"
          expect(map[:rake]).to eq("rvm 3.3.0 do rake")
        end
      end

      describe "#clear" do
        it "forgets explicit mappings" do
          command_map[:rake] = "bundle exec rake"
          command_map.clear
          command_map.prefix[:rake] << "rvm 3.3.0 do"

          expect(command_map[:rake]).to eq("rvm 3.3.0 do rake")
        end
      end
    end
  end
end
