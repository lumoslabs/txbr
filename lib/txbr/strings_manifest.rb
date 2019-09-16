module Txbr
  class StringsManifest
    include Enumerable

    def initialize
      @strings ||= {}
    end

    def add(path, value)
      root = path[0...-1].inject(@strings) do |ret, key|
        ret[key] ||= {}
      end

      root[path.last] = value
    end

    def merge(other_manifest)
      self.class.new.tap do |new_manifest|
        new_manifest.merge!(self)
        new_manifest.merge!(other_manifest)
      end
    end

    def merge!(other_manifest)
      other_manifest.each_string do |path, value|
        add(path, value)
      end
    end

    def to_h
      @strings
    end

    def each(&block)
      return to_enum(__method__) unless block_given?
      each_helper(@strings, [], &block)
    end

    alias each_string each

    def empty?
      @strings.empty?
    end

    private

    def each_helper(root, path, &block)
      case root
        when Hash
          root.each_pair do |key, child|
            each_helper(child, path + [key], &block)
          end

        else
          yield path, root
      end
    end
  end
end
