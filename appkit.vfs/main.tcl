
set APP_DIR [file dir [info script]]

set pixit_sizex  8
set pixit_sizey  8
set pixit_size  16

set pixit_db [dict create]

set pixit_filetypes {
  {"Pixit Files" ".pixit"}
  {"XBM Files"   ".xbm"}
  {"All Files"   "*"}
}


bind . <F12> "console show"


source $APP_DIR/res/photo.tcl

#--------------------------------------------#

wm title . "Pixit"

#--------------------------------------------#

pack [frame .actions] -side bottom -fill x
pack [button .actions.fopen -height 2 -text "Open" -command "pixit_fopen" \
    -image fileopen22 -compound left \
  ] -side left -fill both -expand 1
pack [button .actions.fsave -text "Save" -command "pixit_fsave" \
    -image filesave22 -compound left \
  ] -side left -fill both -expand 1
pack [button .actions.preview -text "Preview" -command "pixit_preview" \
    -image viewmag22 -compound left \
  ] -side left -fill both -expand 1
pack [button .actions.about -text "About" \
    -image acthelp22 -compound left \
  ] -side left -fill both -expand 1


#--------------------------------------------#

pack [frame .flist] -side left -fill y
pack [scale  .s -orient horizontal -from 1 -to 32 -variable pixit_size -command pixit_redraw] -side bottom -fill x
pack [canvas .c] -side bottom -fill both -expand 1
pack [frame .f] -side right

#--------------------------------------------#

tk_optionMenu .f.style pixit_style "square" "circle"


pack [spinbox .f.nx   -textvar pixit_sizex -width 4 -from 1 -to 256] -side left
pack [label  .f.x     -text "x"] -side left
pack [spinbox .f.ny   -textvar pixit_sizey -width 4 -from 1 -to 256] -side left
pack .f.style -side left
pack [button .f.clear -text "Reset" -command "pixit_reset" \
    -image actreload16 -compound left \
  ] -side left -fill x


# pack [frame .fs] -side top -fill x
# pack [button .fs.open -text "Open" -command "pixit_fopen"] -side left -fill x -expand 1
# pack [button .fs.save -text "Save" -command "pixit_fsave"] -side left -fill x -expand 1
# pack [button .preview -text "Preview All" -command pixit_preview ] -side top -fill x


pack [listbox .list] -side bottom -fill both -expand 1 -in .flist
pack [entry  .flist.name  -textvar pixit_name] -side left
pack [button .flist.apply -text "Add"  -command "pixit_save" -image actitemadd16 -compound left]  -side left

bind .c    <1>                     "pixit_click %x %y"
bind .c    <Button1-Motion>        "pixit_click %x %y 1"
bind .c    <Button3-Motion>        "pixit_click %x %y -1"
bind .list <Double-1> "pixit_load"

proc xbm_save {file data} {
  set width  [string length [lindex $data 0]]
  set height [llength $data]

  set bytes [list]
  foreach line $data {
    binary scan [binary format b* $line] cu* bytes_line
    set row [list]
    foreach b $bytes_line { lappend row [format "0x%x" $b] }
    lappend bytes [join $row ","]
  }

  set fout [open $file w]
  puts $fout "#define i_width  $width"
  puts $fout "#define i_height $height"
  puts $fout "static char i_bits\[\] = {"
  puts $fout [join $bytes ",\n"]
  puts $fout "}"
  close $fout

  return
}

proc pixit_fsave {} {
  set file [tk_getSaveFile -defaultextension ".pixit" -filetypes $::pixit_filetypes]

  if {$file eq ""} {
    return
  }

  set ext [file ext $file]

  switch $ext {
    .xbm {
      set data [pixit_get]
      xbm_save $file $data
    }
    default {
     set fout [open $file w]
     puts $fout [format "return {\n%s\n}" $::pixit_db]
     close $fout
    }
  }

}

proc pixit_fopen {} {
  set file [tk_getOpenFile -defaultextension ".pixit" -filetypes {{"Pixit File" ".pixit"}}]

  if {$file eq ""} {
    return
  }

  set ::pixit_db [source $file]
  pixit_reset
  pixit_list
}

set text_pt 0.7
set text_px 4
set text_cw 28
set text_ch 36

proc preview.redraw {win args} {
  set OX 32
  set OY 32

  set Y $OX
  set X $OY

  set unit "mm"
  set unit ""

  $win.canvas delete all
  set pt [expr {$::text_px*$::text_pt}]

  set idx 0
  dict for {name data} $::pixit_db {
    incr idx

    set y $Y 
    foreach line [split $data "\n"] {
      set x $X
      foreach v [split $line ""] {
        if {$v} {
          $win.canvas create oval ${x}$unit ${y}$unit [expr $x+$pt]$unit [expr $y+$pt]$unit -fill red -width 0
	}
        set x [expr {$x+$::text_px}]
      }
      set y [expr {$y+$::text_px}]
    }

    set X [expr $X+ $::text_cw]

    if {$idx%9==0} {
      set Y [expr $Y+$::text_ch]
      set X $OX
    }
  }

}

proc pixit_preview {} {
  set win .fpreview
  toplevel $win
  wm title $win "Pixit - Preview"
  pack [frame $win.ctrl] -side bottom -fill x -expand 1
  pack [canvas $win.canvas] -side bottom -fill both -expand 1
  pack [frame $win.f] -side top -fill x


  pack [label  $win.f.lpt -text "Pixle:"] -side left
  pack [ttk::spinbox $win.f.ps -width 4 -textvar text_px -from 1 -to 16 ] -side left
  pack [label  $win.f.sp -text "/"] -side left
  pack [ttk::spinbox $win.f.pt -width 4 -textvar text_pt -from 0 -to 1.0 -incr 0.1] -side left

  pack [label  $win.f.lchar -text " Char:"] -side left
  pack [entry  $win.f.cw -width 6 -textvar text_cw] -side left
  pack [label  $win.f.x1 -text "x"] -side left
  pack [entry  $win.f.ch -width 6 -textvar text_ch] -side left
  pack [button $win.f.redraw -text "Redraw" -command [list preview.redraw $win]] -side left -fill x -expand 1

  preview.redraw $win
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
  for {set j 0} {$j<$::pixit_sizey} {incr j} {
    for {set i 0} {$i<$::pixit_sizex} {incr i} {
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
  for {set j 0} {$j<$::pixit_sizey} {incr j} {
    for {set i 0} {$i<$::pixit_sizex} {incr i} {
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
