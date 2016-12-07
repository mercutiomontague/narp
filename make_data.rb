#!/usr/bin/env ruby

require 'date'

@rand = Random.new
@colors = %w{yellow green violet red blue purple fusia}
@names = %w{Sonny Aria Inara Sheila Chris Catherine Heathcliff Jane Tarzan}
@adjectives = %w{loud bombastic sychophantic manipulative obsequious fawning}
@verbs = %w{vault stab jump punch peruse}
@adverbs = %w{proudly haughtily cautiously manaminously flauntingly}
@dates = ['2015-12-25 11:29:00', '2009-02-28 19:05:00', '2006-03-09 23:23:02', '2000-01-21 01:21:20'].collect{|s| DateTime.parse(s)}

@month_short_name = %w{jan feb mar apr may jun jul aug sep oct nov dec}
@month_name = %w(january february march april may june july august september october november december)

                                                                                  

def date1(d)
  sprintf("%02d/%04d-%02d %d:%02d:%02d", d.month, d.year.to_i, d.day, d.hour, d.minute, d.second)
end


def date2(d)
  sprintf("%02d/%s/%d %02d:%02d:%02d %s", d.year, @month_short_name[d.month - 1], d.day, d.hour > 12 ? d.hour - 12 : d.hour, d.minute, d.second, d.hour > 12 ? 'p.m.' : 'a.m.')
end

def date3(d)
  sprintf("%s %d%s, %d %02d%02d:%02d", @month_name[d.month - 1], d.day, day_suffix(d.day), d.year, d.hour, d.minute, d.second)
end

def day_suffix(num)
  if [1, 21, 31].detect{|d| d == num}
    'st'
  elsif [2, 22].detect{|d| d == num}
    'nd'
  elsif [3, 23].detect{|d| d == num}
    'rd'
  else
    'th'
  end
end


maxrows = 10000
File.open('features/fixtures/data_1', 'w') {|fh|
  (1..maxrows).each {|i|
    idx = (@rand.rand * @dates.size ).to_i
    d = @dates[ idx ]
    fh.puts [
      i, 
      date1(d),
      date2(d),
      date3(d),
      @colors[ (@rand.rand*@colors.size).to_i ], 
      @names[ (@rand.rand*@names.size).to_i ],
      @adverbs[ (@rand.rand*@adverbs.size).to_i ],
      @verbs[ (@rand.rand*@verbs.size).to_i ],
      @adjectives[ (@rand.rand*@adjectives.size).to_i ],
      (100*@rand.rand).to_i,
    ].join("\t")
  }
}




