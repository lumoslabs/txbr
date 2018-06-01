require 'spec_helper'

describe Txbr::Utils do
  describe '.url_join' do
    it 'joins urls' do
      expect(described_class.url_join(*%w(http://foo.bar baz boo))).to(
        eq('http://foo.bar/baz/boo')
      )
    end

    it 'joins urls with leading slashes' do
      expect(described_class.url_join(*%w(http://foo.bar/ baz /boo))).to(
        eq('http://foo.bar/baz/boo')
      )
    end
  end
end
