require 'sidekiq'
require 'sidekiq/util'

# Sidekiq::Cron::Namespace
module Sidekiq
  module Cron
    class Namespace
      def self.all
        namespaces = nil

        Sidekiq.redis do |conn|
          namespaces = conn.keys('cron_jobs:*').collect do |key|
            key.split(':').last
          end
        end

        # Adds the default namespace if not present
        has_default = namespaces.detect do |name|
          name == Sidekiq::Cron.configuration.default_namespace
        end

        unless has_default
          namespaces << Sidekiq::Cron.configuration.default_namespace
        end

        namespaces
      end

      def self.all_with_count
        namespaces = []

        all.each do |name|
          namespace = { name: name }

          Sidekiq.redis do |conn|
            namespace[:count] = count name
          end

          namespaces << namespace
        end

        namespaces
      end

      def self.count(name = Sidekiq::Cron.configuration.default_namespace)
        out = 0
        Sidekiq.redis do |conn|
          out = conn.scard("cron_jobs:#{name}")
        end
        out
      end
    end
  end
end
