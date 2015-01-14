#  enumchron -- an experimental enumchron parser

This is an experimental enumchron parser for "enumeration/chronology" data
in library metadata.

It is incomplete.

It attempts to first parse, and then transform, enumchron entries with
the following data, assuming reasonable use of lists and abbreviations

* volume
* number
* year (including simple ranges, but not yet slashed years like 1993/94)
* part
* copy
* series
* report
* section
* appendix
* title number
* sudocs
* supplement (either with a list or whatever the given text was)
* incomplete (true or false)
* annual/annual summary (true or false)
* things in parentheses


It currently deals imperfectly with

* Months (will parse months, but doesn't associate with years correctly)

I'd like to make it work with:

* Ordinals (1st, 2nd, etc)
* Number-letter enumerations (v. 2a-2d)
* Seasons (winter, summer)
* Slashed years (1993/94-1998/99)
* More complete dates (year/month/day in any combination)


## Lists

Most enumeration lists can be dealt with as long as they're not too
stupid. Things like "v 1-3,5,8-11" are fine, as are "v n-z" to get
character ranges. More complex stuff that mixes numbers and letters
doesn't work.


## Usage

You can run tests from the command line with the `testparse` script in
the root directory

```bash

testparse "v.43:no.2 (1976 May)"

-----------original
v.43:no.2 (1976 May)
-----------parses to
[{:volumes=>{:numeric=>{:single=>{:d=>"43"@2}}}},
 {:numbers=>{:numeric=>{:single=>{:d=>"2"@8}}}},
 {:iyears=>{:single=>"1976"@11}},
 {:months=>{:single=>"may"@16}}]
-----------transforms to
[{:volumes=>#<Enumchron::IntList:0x007fe673971330 @data=[43]>},
 {:numbers=>#<Enumchron::IntList:0x007fe673960f08 @data=[2]>},
 {:years=>[1976]},
 {:months=>"may"@16}]


testparse "v3-4,6 no. 110-133,138-142 1997-1999 (copy 2)"

-----------original
v3-4,5 no. 110-133,138-142 1997-1999 (copy 2)
-----------parses to
[{:volumes=>
   {:numeric=>
     [{:range=>{:start=>{:d=>"3"@1}, :end=>{:d=>"4"@3}}},
      {:single=>{:d=>"5"@5}}]}},
 {:numbers=>
   {:numeric=>
     [{:range=>{:start=>{:d=>"110"@11}, :end=>{:d=>"133"@15}}},
      {:range=>{:start=>{:d=>"138"@19}, :end=>{:d=>"142"@23}}}]}},
 {:iyears=>{:range=>{:year_range=>{:start=>"1997"@27, :end=>"1999"@32}}}},
 {:copies=>{:numeric=>{:single=>{:d=>"2"@43}}}}]
-----------transforms to
[{:volumes=>#<Enumchron::IntList:0x007f943407bf50 @data=[3..4, 6]>},
 {:numbers=>#<Enumchron::IntList:0x007f9434038b60 @data=[110..133, 138..142]>},
 {:years=>[1997..1999]},
 {:copies=>#<Enumchron::IntList:0x007f9434063f40 @data=[2]>}]
```

You can also, of course, use it right from ruby code:

```ruby

$:.unshift 'lib' # or wherever enumchron is, if you haven't installed as a gem
require 'enumchron'

p = Enumchron::Parser.new
t = Enumchron::Transform.new

s = "the string you want to parse"
begin
  parsed = p.parse(Enumchron::Parser.preprocess_line(s))
  puts "#{s} => #{t.appy(parse)"
rescue Parslet::ParseFailed
  puts "Failed to parse #{s}"
end

```
