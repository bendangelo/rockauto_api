# frozen_string_literal: true

module RockautoApi
  class Cache
    def initialize(store: nil)
      @store = store
      @memory = {}
    end

    def fetch(key, ttl: 3600)
      if @store
        @store.fetch(key, expires_in: ttl) { yield }
      else
        @memory[key] ||= yield
      end
    end

    def delete(key)
      if @store
        @store.delete(key)
      else
        @memory.delete(key)
      end
    end

    def clear
      if @store
        @store.clear
      else
        @memory.clear
      end
    end
  end
end
