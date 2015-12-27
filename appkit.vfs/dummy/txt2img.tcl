
console show

set font_size 16

pack [text .log -height 12] -side bottom -fill both -expand 0
pack [canvas .c -background white] -side right -fill both -expand 1 
pack [spinbox .font_size -textvar font_size -from 12 -to 36 -justify right] -side top -fill x -expand 0
pack [listbox .fonts] -side top -fill both -expand 1

set font "fixed 16"
.c create text {10 30} -font $font -anchor w -text "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
.c create text {10 60} -font $font -anchor w -text "0123456789"

foreach font [font families] {

  if [string match "@*" $font] continue

  set font [list $font]

  set metrics [font metrics $font]
  if [dict get $metrics -fixed] {
     puts "$font $metrics"
     .fonts insert end [lindex $font 0]
  }
}

proc log {msg} {
  .log insert end "$msg\n"
}

proc update_font {} {
  set font [.fonts get active]

  set font [list $font $::font_size]
  .c delete all

  #{DotumChe 16} 11 22 {-ascent 18 -descent 3 -linespace 21 -fixed 1}

  set metrics [font metrics $font]
  set H [dict get $metrics -linespace]
  set W [font measure $font "ABCDEFGHIJKLMNOPQRSTUVWXYZ"]

  set x 24
  set y 24
  .c create line "$x 0 $x 800"
  .c create line "0 $y 800 $y"

  incr x
  incr y
  .c create text "$x $y" -font $font -anchor nw -text "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  incr y $H
  .c create line "0 $y 800 $y"
  incr y
  .c create text "$x $y" -font $font -anchor nw -text "0123456789"
  incr y $H
  .c create line "0 $y 800 $y"
  incr x $W
  .c create line "$x 0 $x 800"

  .c postscript -colormode mono -file test.ps
  log [list $font [font measure $font "A"] [font measure $font "AB"] [font metrics $font]]
}

bind .fonts <Double-1> update_font
