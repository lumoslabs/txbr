require 'liquid'

module Txbr
  module Liquid
    # Used to stand in for the special Braze {% abort_message(...) %} tag.
    # Renders as an empty string.
    class AbortMessageTag < ::Liquid::Tag
      def initialize(_tag_name, _arg, _context = nil)
      end

      def render(_context)
        ''
      end
    end
  end
end
