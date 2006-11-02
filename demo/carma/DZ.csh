#!/bin/csh -vf

echo EZ.csh

#echo "Compare D and DZ" >>  sat1mm.modj2.results


 foreach DEC (22)
  foreach SIZE (.05)

   hex7-23.csh     EZ  $DEC $SIZE
   default7-23.csh EZ  $DEC $SIZE
   joint7-23.csh   EZ  $DEC $SIZE

   hex7-15.csh     D  $DEC $SIZE
   default7-15.csh D  $DEC $SIZE
   joint7-15.csh   D  $DEC $SIZE

   hex7-23.csh     DZ  $DEC $SIZE
   default7-23.csh DZ  $DEC $SIZE
   joint7-23.csh   DZ  $DEC $SIZE
 end
end

end:
