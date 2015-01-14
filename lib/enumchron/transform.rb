require 'parslet'
require 'forwardable'


module Enumchron
  class Range
    attr_accessor :begin, :end

    def initialize(b, e)
      @begin = b
      @end   = e
    end

    def to_i
      (@begin.to_i)..(@end.to_i)
    end

    def to_s
      (@begin.to_s)..(@end.to_s)
    end

  end

  class IntList
    extend Forwardable
    include Enumerable

    def_delegators :@data, :each, :[], :[]=, :first, :last, :<<

    def initialize(args)
      @data = Array[args].flatten
    end

  end
  class CharList < IntList;end

  Numlet = Struct.new(:num, :let)



end


class Enumchron::Transform < Parslet::Transform

  # We have all sorts of supporting classes and methods first
  # remove leading zeros and turn into an int
  def self.rlzint(x)
    Integer(x.to_s.gsub(/\A0+/, ''))
  end

  RangeEndpoints = Struct.new(:firstval, :lastval) do
    def to_irange
      rlzint(firstval)..rlzint(lastval)
    end

    def to_charrange
      (firstval.to_s)..(lastval.to_s)
    end
  end



  def self.to_i_or_irange(x)
    if x.respond_to? :to_irange
      x.to_irange
    else
      # remove leading zeros
      rlzint(x)
    end
  end

  def to_char_or_charrange(x)
    if x.respond_to? :to_charrange
      x.to_charrange
    else
      x.to_s
    end
  end


  def self.year_endpoint_transform(f, s)
    return f, s if f.is_a? DualYear or s.is_a? DualYear
    f = f.to_s
    s = s.to_s

    fint = rlzint(f)
    sint = rlzint(s)


    if f.size == 4 and s.size == 2
      if (fint % 100) > sint
        s = (fint / 100 + 1).to_s + s
      else
        s = f[0..1] + s
      end
    end

    if f.size == s.size and s.size == 2
      # TODO
      # Need to interpret this based on incoming years;
      # Right now, assume 1999/2001
      if fint > sint
        f = '19' + f
        s = '20' + s
      else # assume 20th century
        f = '19' + f
        s = '19' + s
      end
    end
    f = rlzint(f) if f.is_a? String
    s = rlzint(s) if s.is_a? String
    return f, s
  end

  def slashed_year(f, s, year1 = 1900, year2 = 2050)
    f, s = year_endpoint_transform(f, s)
    raise "Weird slashed year thingy" if s <= f
    if s == f + 1
      DualYear.new(f.to_i, s.to_i)
    else
      YearRange.new(f.to_i, s.to_i)
    end
  end

  Numlet = Struct.new(:num, :let)

  DualYear = Struct.new(:firstval, :lastval) do
    def to_i
      self
    end
  end

  DualRange = Struct.new(:firstval, :lastval)

  YearRange = Struct.new(:firstval, :lastval) do
    def to_i
      begin
        firstval..lastval
      rescue ArgumentError
        DualRange.new(firstval, lastval)
      end

    end
  end


  rule(:d => simple(:x)) { x }
  rule(:single => simple(:x)) { x }

  rule(:range => {:start => simple(:s), :end => simple(:e)}) { Enumchron::Range.new(s, e) }

  rule(:numeric => simple(:x)) { Enumchron::IntList.new(x.to_i)}
  rule(:numeric => sequence(:a)) { Enumchron::IntList.new(a.map(&:to_i)) }

  rule(:letters => simple(:x)) { Enumchron::CharList.new(x.to_s) }
  rule(:letters => sequence(:a)) { Enumchron::CharList.new(a.map(&:to_s))}


  #rule(:year_dual => {:start => simple(:s), :end => simple(:e)}) { slashed_year(s, e) }
  rule(:year_range => {:start => simple(:s), :end => simple(:e)}) { YearRange.new(*Enumchron::Transform.year_endpoint_transform(s, e)) }
  #

  rule(:range => simple(:x)) { x }
  rule(:iyears => simple(:x)) { {:years => [x.to_i]} }
  rule(:iyears => sequence(:a)) { {:years => a.map { |x| x.to_i }} }

  rule(:eyears => simple(:x)) { {:years => [x.to_i]} }
  rule(:eyears => sequence(:a)) { {:years => a.map { |x| x.to_i }} }

  rule(:incompl => simple(:x)) { {:incomplete => true}}

  # numlets just plain aren't working yet. V. complex
  #
  #rule(:numlets => {:single => {:numpart => simple(:n), :letpart => simple(:l)}}) { Enumchron::Numlet.new(Integer(n), l) }

end

