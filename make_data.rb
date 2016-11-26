#!/usr/bin/env ruby

@rand = Random.new
def header_row
  ['blue', 'cheese', '0000019', 'is awesome'].join("\t")
end

def billing_row
  ['yellow', 'cheese', '00001' << (@rand.rand * 20).to_i.to_s, 'is awesome'].join("\t")
end

def remainder_row
  ["I don't", 'like', '       ', 'eese'].join("\t")
end

maxrows = 10000
File.open('features/fixtures/data_2016-11-03.txt', 'w') {|fh|
  (1..maxrows).each {|i|
      r = case (@rand.rand * 3).to_i
        when 0
          header_row
        when 1 
          billing_row
        when 2
          remainder_row
      end
      # fh.puts r
      # fh.print "#{r}\r"
      fh.print "#{r}\r\n"
  }
}




