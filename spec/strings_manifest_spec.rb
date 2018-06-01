require 'spec_helper'

describe Txbr::StringsManifest do
  let(:manifest) { described_class.new }

  describe '#add' do
    it 'adds the string with the given path' do
      manifest.add(%w(foo bar), 'baz')
      expect(manifest.to_h).to eq(
        { 'foo' => { 'bar' => 'baz' } }
      )
    end

    it 'nests correctly' do
      manifest.add(%w(foo bar), 'baz')
      manifest.add(%w(foo baz boo), 'bizz')
      expect(manifest.to_h).to eq(
        { 'foo' => { 'bar' => 'baz', 'baz' => { 'boo' => 'bizz' } } }
      )
    end
  end

  describe '#merge!' do
    it 'merges the strings from another manifest into this one' do
      other = described_class.new
      other.add(%w(foo bar), 'baz')
      manifest.add(%w(foo baz boo), 'bizz')
      manifest.merge!(other)
      expect(manifest.to_h).to eq(
        { 'foo' => { 'bar' => 'baz', 'baz' => { 'boo' => 'bizz' } } }
      )
    end
  end

  describe '#each' do
    it 'yields each path and corresponding value' do
      manifest.add(%w(foo bar), 'baz')
      manifest.add(%w(foo baz boo), 'bizz')

      expect(manifest.each.to_a).to(
        eq([[['foo', 'bar'], 'baz'], [['foo', 'baz', 'boo'], 'bizz']])
      )
    end
  end
end
