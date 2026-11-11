# frozen_string_literal: true

# Extends SSHKit's command map so that command prefixes and explicit command
# mappings compose instead of conflicting.
#
# SSHKit's command map offers two ways to customize how a command is run:
#
# * `SSHKit.config.command_map[:rake] = "bundle exec rake"` replaces the
#   command entirely.
# * `SSHKit.config.command_map.prefix[:rake] << "rvm 3.3.0 do"` prepends to
#   the command.
#
# When both are used for the same command (e.g. a Ruby version manager plugin
# adds a prefix, while the user's deploy.rb maps the command through a wrapper
# such as a secrets-manager shim), SSHKit silently drops the explicit mapping
# and runs the bare command instead
# (https://github.com/capistrano/capistrano/issues/2192).
#
# We make the two features compose: prefixes are prepended to the mapped
# command, falling back to the bare command name when no explicit mapping
# exists. This preserves the previous behavior in all cases except the broken
# one.
module Capistrano
  module SSHKitExt
    module CommandMapExt
      def initialize(value=nil)
        super
        value&.each_key { |command| explicit_mappings[command.to_sym] = true }
      end

      def []=(command, new_command)
        explicit_mappings[command.to_sym] = true
        super
      end

      def [](command)
        if prefix[command].any?
          prefixes = prefix[command].map { |prefix| prefix.respond_to?(:call) ? prefix.call : prefix }
          prefixes = prefixes.join(" ")

          "#{prefixes} #{mapped_command(command)}"
        else
          super
        end
      end

      def clear
        explicit_mappings.clear
        super
      end

      private

      # Returns the mapped command for the given command, falling back to the
      # bare command name when no explicit mapping exists. Note we cannot
      # simply use @map[command] here: for unmapped commands it returns the
      # default `/usr/bin/env <command>` string, which was historically not
      # used in the prefix branch.
      def mapped_command(command)
        mapped = nil
        if explicit_mappings.key?(command.to_sym)
          mapped = @map[command]
          mapped = mapped.call if mapped.respond_to?(:call)
        end
        mapped || command.to_s
      end

      def explicit_mappings
        @explicit_mappings ||= {}
      end
    end
  end
end

SSHKit::CommandMap.prepend(Capistrano::SSHKitExt::CommandMapExt)
