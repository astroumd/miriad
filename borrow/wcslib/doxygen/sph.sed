/^[^*]/{p;d;}

s|\([1-9][0-9]*\) degrees|@f$\1^\\circ@f$|g
s| 0 or | @f$0^\\circ@f$ or |
s|cos(|@f$cos@f$(|g
s|sin(|@f$sin@f$(|g
