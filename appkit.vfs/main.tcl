
set pixit_sizex  8
set pixit_sizey  8
set pixit_size  16

set pixit_db [dict create]


bind . <F12> "console show"

pack [frame .f] -side right -fill both -expand 1

pack [scale .f.s -orient horizontal -from 1 -to 32 -variable pixit_size -command pixit_redraw] -side bottom -fill x
pack [canvas .c]     -side bottom -fill both -expand 1 -in .f
pack [button .f.clear -text "Reset" -command "pixit_reset"] -side right
tk_optionMenu .f.style pixit_style "square" "circle"
pack .f.style -side right
pack [spinbox .f.ny   -textvar pixit_sizey -width 4 -from 1 -to 256] -side right
pack [label  .f.x     -text "x"] -side right
pack [spinbox .f.nx   -textvar pixit_sizex -width 4 -from 1 -to 256] -side right


pack [frame .fs] -side top -fill x
pack [button .fs.open -text "Open" -command "pixit_fopen"] -side left -fill x -expand 1
pack [button .fs.save -text "Save" -command "pixit_fsave"] -side left -fill x -expand 1
pack [listbox .list] -side top -fill both -expand 1

pack [entry  .name  -textvar pixit_name] -side left
pack [button .apply -text "Add"  -command "pixit_save"]  -side left

bind .c    <1>                     "pixit_click %x %y"
bind .c    <Button1-Motion>        "pixit_click %x %y 1"
bind .c    <Button3-Motion>        "pixit_click %x %y -1"
bind .list <Double-1> "pixit_load"

proc pixit_fsave {} {
  set file [tk_getSaveFile -defaultextension ".pixit"]
  set fout [open $file w]
  puts $fout [format "return {\n%s\n}" $::pixit_db]
  close $fout
}

proc pixit_fopen {} {
  set file [tk_getOpenFile -defaultextension ".pixit" -filetypes {{"Pixit File" ".pixit"}}]
  set ::pixit_db [source $file]
  pixit_reset
  pixit_list
}

proc pixit_click {x y {motion 0}} {
  
  if {$x > $::pixit_ulx && $x < $::pixit_lrx} {
    if {$y > $::pixit_uly && $y < $::pixit_lry} {

      set idx [expr {($x - $::pixit_ulx)/$::pixit_size}]
      set idy [expr {($y - $::pixit_uly)/$::pixit_size}]

      set tag "pix_${idx}_${idy}"

      set color [.c itemcget $tag -fill]


      if {$motion==0} {
        .c itemconfigure $tag -fill [expr {($color eq "red")?"":"red"}]
      } elseif {$motion > 0} {
          if {$color eq ""} {
            .c itemconfigure $tag -fill red
	  }
      } else {
          if {$color eq "red"} {
            .c itemconfigure $tag -fill ""
	  }
      }
    }
  }
}

proc pixit_load {} {
  set name [.list get active] 
  set ::pixit_name $name

  set data [dict get $::pixit_db $name]

  pixit_set $data
}

proc pixit_set {data} {
  pixit_reset

  set y 0
  foreach line [split $data "\n"] {
    set x 0
    foreach v [split $line ""] {
      set tag "pix_${x}_${y}"
      .c itemconfigure $tag -fill [expr {($v eq "0")?"":"red"}]
      incr x
    }
    incr y
  }
}

proc pixit_get {} {
  set x 0
  set y 0

  set pixtext ""
  for {set j 0} {$j<=$::pixit_sizey} {incr j} {
    for {set i 0} {$i<=$::pixit_sizex} {incr i} {
      set tag "pix_${i}_${j}"
      set color [.c itemcget $tag -fill]
      if {$color eq ""} {
        append pixtext 0
      } else {
        append pixtext 1
      }
    }
    append pixtext "\n"
  }
  
  set pixtext [string trim $pixtext]

  return $pixtext
}

proc pixit_save {} {

  set pixtext [pixit_get]

  puts $pixtext

  set exist [dict exists $::pixit_db $::pixit_name]

  dict set ::pixit_db $::pixit_name $pixtext

  if {!$exist} {
    pixit_list
  }
}

proc pixit_list {} {

  .list delete 0 end
  dict for {name -} $::pixit_db {
    .list insert end "$name"
  }
}


proc pixit_redraw {args} {
  set data [pixit_get]
  pixit_reset
  pixit_set $data
}

proc pixit_reset {} {
  .c delete all

  set size $::pixit_size

  set w [expr {$size*$::pixit_sizex}]
  set h [expr {$size*$::pixit_sizey}]

  set y 0
  for {set i 0} {$i<=$::pixit_sizey} {incr i} {
    .c create line [list 0 $y $w $y] -fill gray -width 1
    incr y $size
  }

  set x 0
  for {set i 0} {$i<=$::pixit_sizex} {incr i} {
    .c create line [list $x 0 $x $h] -fill gray -width 1
    incr x $size
  }

  set x 0
  set y 0
  for {set j 0} {$j<=$::pixit_sizey} {incr j} {
    for {set i 0} {$i<=$::pixit_sizex} {incr i} {
      set tag "pix_${i}_${j}"

      switch $::pixit_style {
	"circle" {
          .c create oval [list \
	     [expr {$x+1}] [expr {$y+1}] \
	     [expr {$x+$size-2}] [expr {$y+$size-2}]] -fill "" -width 0 -tags $tag
	}
        "square" {
          .c create rectangle [list $x $y [expr {$x+$size}] [expr {$y+$size}]] -fill "" -width 0 -tags $tag
        }
	default {
          .c create rectangle [list $x $y [expr {$x+$size}] [expr {$y+$size}]] -fill "" -width 0 -tags $tag
	}
      }
      incr x $size
    }
    set  x 0
    incr y $size
  }

  # set W [.c cget -width]
  # set H [.c cget -height]

  set W [winfo width  .c ]
  set H [winfo height .c ]

  set dx [expr {($W-$w)>>1}]
  set dy [expr {($H-$h)>>1}]

  .c move all $dx $dy

  set ::pixit_ulx $dx
  set ::pixit_uly $dy
  set ::pixit_lrx [expr {$dx + $w}]
  set ::pixit_lry [expr {$dy + $h}]

  # .c scan mark 0 0
  # .c scan dragto 60 60 1

  # pixit_list
}

pixit_reset
if {[llength $::argv]} {
  set pixit_db [source [lindex $::argv 0]]
  pixit_list
}
