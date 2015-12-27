
set ptfonts_7x9 {
  A {
    { }
    { }
  }
}

proc parse_font_image {ppmfile} {
  set fp [open $ppmfile rb]
  set magic [gets $fp] ;# P6
  gets $fp ;# comment
  lassign [gets $fp] width height
  lassign [gets $fp] maxval

  switch $magic {
    "P6" {
      set bytes [read $fp]
      binary scan $bytes cu* pixels
    }
    "P3" {
      set pixels [read $fp]
    }
  }

  set x 0
  set y 0
  set points [list]

  set bgcolor [lindex $pixels 0] 

  foreach {r g b} $pixels {

    # puts "($x $y) = $r $g $b"
    if {$r==$bgcolor && $g==$bgcolor && $b==$bgcolor} {
      lappend points 0
    } else {
      lappend points 1

      if {$y==0 || $x==0} {
	lappend anchors [list $x $y]
      }
    }

    incr x
    if {$x>=$width} {
      set x 0
      incr y
    }
  }

  set x1 [lindex $anchors 0 0]
  set x2 [lindex $anchors 1 0]
  set y1 [lindex $anchors 2 1]
  set y2 [lindex $anchors 3 1]

  set char_width  [expr {($x2-$x1-1)/26}]  ;# TODO
  set char_height [expr {($y2-$y1-1)}]       ;# TODO
  puts "char_size = $char_width x $char_height"

  set chars [split "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ""]

  for {set idx 0} {$idx<26} {incr idx} {

    set cx1 [expr {$x1+$char_width*$idx+1}]
    set cx2 [expr {$cx1+$char_width-1}]
    set cy1 [expr {$y1+1}]
    set cy2 [expr {$cy1+$char_height-1}]


    set pts [list]
    for {set j $cy1} {$j<=$cy2} {incr j} {
      set row [list]
      for {set i $cx1} {$i<=$cx2} {incr i} {
         set pt [lindex $points [expr {$j*$width+$i}]]
	 lappend row $pt
      }
      lappend pts $row
    }

    set char [lindex $chars $idx]
    dict set charpts [lindex $chars $idx] $pts
  }

  return $charpts

}

set charpts [parse_font_image [lindex $::argv 0]]

# puts $charpts
# exit


proc draw_font_points {char rect resample} {

  lassign $rect ulx uly lrx lry 

  set points [dict get $::charpts $char]

  puts "$char $points" 
  if {$resample ne ""} {
    lassign $resample grx gry
    set points [points_resample $points $grx $gry]
  }


  set ny [llength $points]
  set nx [llength [lindex $points 0]]

  set dx [expr {($lrx-$ulx)*1.0/$nx}]
  set dy [expr {($lry-$uly)*1.0/$ny}]

  set ox $ulx
  set oy $uly

  set x $ox
  set y $oy


  foreach row $points {
    foreach pt $row {
      if {$pt} {
        .c create rectangle [list $x $y [expr {$x+1}] [expr {$y+1}]] -fill red -width 0
      }

      set x [expr {$x+$dx}]
    }

    set x $ox
    set y [expr {$y+$dy}]
  }

  return
}

proc draw_points {points rect} {

  lassign $rect ulx uly lrx lry


  set ny [llength $points]
  set nx [llength [lindex $points 0]]

  set dx [expr {($lrx-$ulx)*1.0/$nx}]
  set dy [expr {($lrx-$ulx)*1.0/$ny}]

  set ox $ulx
  set oy $uly

  set x $ox
  set y $oy

  foreach row $points {
    foreach pt $row {
      if {$pt} {
        .c create rectangle [list $x $y [expr {$x+$dx}] [expr {$y+$dy}]] -fill red -width 0
      }

      set x [expr {$x+$dx}]
    }

    set x $ox
    set y [expr {$y+$dy}]
  }

  return
}

proc points_resample {points ngx ngy} {
  set ny [llength $points]
  set nx [llength [lindex $points 0]]
  set gx 0
  set gy 0
  set idx 0
  set idy 0
  foreach row $points {
    foreach pt $row {
      set gx [expr {$ngx*$idx/$nx}]
      set gy [expr {$ngy*$idy/$ny}]

      if {$pt} {
	incr count($gx,$gy)
      } else {
	incr count($gx,$gy) 0
      }

      incr idx
    }

    set idx 0
    incr idy
  }

  # puts [array get count]

  set result [list]
  for {set y 0} {$y<$ngy} {incr y} {
    set row [list]
    for {set x 0} {$x<$ngx} {incr x} {
      if {$count($x,$y)>=1} {
        lappend row 1
      } else {
        lappend row 0
      }
    }
    lappend result $row
  }

  return $result
}


proc draw_font_drill {char rect} {

  lassign $rect ulx uly lrx lry ngx ngy

  set points [dict get $::charpts $char]


  set ny [llength $points]
  set nx [llength [lindex $points 0]]

  set dx [expr {($lrx-$ulx)*1.0/$nx}]
  set dy [expr {($lrx-$ulx)*1.0/$ny}]

  set ox $ulx
  set oy $uly

  set x $ox
  set y $oy

  set gx 0
  set gy 0
  set idx 0
  set idy 0
  foreach row $points {
    foreach pt $row {
      if {$pt} {
        set gx [expr {$ngx*$idx/$nx}]
        set gy [expr {$ngy*$idy/$ny}]
	incr count($gx,$gy)
      } else {
	incr count($gx,$gy) 0
      }

      incr idx
    }

    set idx 0
    incr idy
  }


  return
}

# points_resample [dict get $::charpts "A"] 9 18
# 
# draw_font_drill "A" {10 30 40 80 9 18}
#  exit


proc draw_all_chars {} {
  set chars [split "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ""]

  set dy $::lineheight
  set dx [expr {$dy/2.0}]

  set x 10
  set y 10
  .c delete all
  foreach char $chars {
    draw_font_points $char [list $x $y [expr {$x+$dx}] [expr {$y+$dy}]] "$::nptx $::npty"
    set x [expr {$x+$dx}]
  }

  return
}


console show

set lineheight 36
set nptx       8
set npty       16

pack [listbox .chars] -side left -fill y
pack [canvas .c] -fill both -expand 1
# pack [button .b -command "scan_image" -text "Scan Image"] -fill x -expand 1

pack [entry .lineheight -textvar lineheight] -side left
pack [entry .input1     -textvar nptx] -side left
pack [entry .input2     -textvar npty] -side left
pack [button .d -command "draw_all_chars" -text "Draw Font"] -side right -fill x -expand 1

foreach char [split "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ""] {
  .chars insert end $char
}

bind .chars <Double-1> update_char

proc update_char {} {
  set char [.chars get active]

  set rect [list 10 10 74 138]
  lassign $rect ulx uly lrx lry 
  set points [dict get $::charpts $char]

  set ny [llength $points]
  set nx [llength [lindex $points 0]]

  set dx [expr {($lrx-$ulx)*1.0/$nx}]
  set dy [expr {($lry-$uly)*1.0/$ny}]

  set ox $ulx
  set oy $uly

  set x $ox
  set y $oy


  .c delete all
  foreach row $points {
    foreach pt $row {
      if {$pt} {
        .c create rectangle [list $x $y [expr {$x+$dx}] [expr {$y+$dy}]] -fill red -width 1
      }

      set x [expr {$x+$dx}]
    }

    set x $ox
    set y [expr {$y+$dy}]
  }

}



proc scan_image {} {
  image create photo t -file consolas.ppm -width 0

  set width  640
  set height 320
  for {set y 0} {$y<$height} {incr y} {
    for {set x 0} {$x<$width} {incr x} {
       if [catch {set color [t get $x $y]} err] {
	 if {$x==0} {
	   set height $y
	   puts "set height $y"
	 } else {
	   set width  $x
	   puts "set width $x"
	 }
	 break
       } else {
	 puts "($x $y) = $color"
       }
    }
  }
}


