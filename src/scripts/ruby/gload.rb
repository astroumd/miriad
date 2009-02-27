#!/usr/bin/env ruby
$-w = true if $0 == __FILE__

# gpdump.rb - Dump antenna gains in a very rudimentary way.

require 'mirdl'
include Mirdl

# Create new Sels object for selection
SELS = Sels.new(256)

#  Get the user parameters.
keyini
vis = keya('vis')
logfile = keya('log')
selInput(SELS)
keyfin

# Validate input
bug('f','Input data-set must be given') unless vis

# Open input
tIn =  hopen(vis,'old')
if !hdprsnt(tIn, 'gains')
  bug('f','Antenna gains information not present')
end

# Determine the various parameters, and check their validity. We have
pretty
# well checked that all is OK before, so nothing should go wrong.
doselect = selProbe(SELS,'time?')
nfeeds = rdhdi(tIn,'nfeeds',1)
ntau   = rdhdi(tIn,'ntau',0)
ngains = rdhdi(tIn,'ngains',1)
nsols  = rdhdi(tIn,'nsols',1)

puts "# nfeeds = #{nfeeds}"
puts "# ntau   = #{ntau  }"
puts "# ngains = #{ngains}"
puts "# nsols  = #{nsols }"

if(nfeeds <= 0 || ntau < 0 || ngains <= 0 || nsols <= 0)
  bug('f','Bad gain table size information')
end

nants = ngains / (nfeeds + ntau)
puts "# nants  = #{nants }"

if(nants*(nfeeds+ntau) != ngains)
  bug('f','Number of gains does equal nants*(nfeeds+ntau)')
end

item = haccess(tIn,'gains','read')

# Determine what we think the number of solutions should be from the
# size of the file.

if(hsize(item) != 8+(ngains+1)*8*nsols)
  bug('f','Gain table does not look the right size')
end

# All is OK. Lets go for it.
tbuf = NArray.float(1)
times = []
gains = []
k = 0
offset = 8

for i in 1..nsols
  t = hreadd(item,tbuf,offset,8)[0]
  offset = offset + 8
  if(doselect)then
    select = SelProbe(SELS,'time',t)
  else
    select = true
  end
  if(select)then
    t0 ||= (t - 1).to_i + 0.5
    times[k] = t - t0
    gains[k] = NArray.scomplex(ngains)
    hreadc(item,gains[k],offset,8*ngains)
    k = k + 1
  end
  offset = offset + 8*ngains
end
if(k == 0)
  bug('f','No gains selected')
end
nsols = k
hdaccess(item)


# Blank out the antenna gains that were not selected.
if(selProbe(SELS,'antennae?',0.0))
  ant = []
  for i in 0...nants
    ant[i] = selProbe(SELS, 'antennae', 257.0*i)
  end

  for k in 0...nsols
    for j in 0...nants
      for i in 0...nfeeds
        if !ant[j]
          gains[k][j*nfeeds+i] = 0
        end
      end
    end
  end
end

# Dump info
for k in 0...nsols
  printf("%.5f", times[k])
  for j in 0...nants
    for i in 0...nfeeds
      g = gains[k][j*nfeeds+i]
      printf(" %.3g%+.3gi", g.real, g.imag)
    end
  end
  printf("\n")
end
