# From: http://wiki.tcl.tk/1846
# strimj = String Image Routines

namespace eval strimj {
    variable Font
    variable defaultColors {
        r red g green b blue c cyan m magenta y yellow o orange . white
    }
    proc bitmap {si args} {eval [list image create bitmap -data [xbm $si]] $args}
    proc char {char {font -}} {
        #--- retrieve an image from the font database
        variable Font
        if [info exist Font($font,$char)] {
            set res $Font($font,$char)
        } else {
            set font $Font(default)
            if [info exist Font($font,$char)] {
                set res $Font($font,$char)
            } else {
                set choices [array names Font *,$char]
                if [llength $choices] {
                    set res $Font([lindex $choices 0])
                } else {set res $Font(unknown)}
            }
        }
        set res
    }
    proc concat {si1 si2 {pad ""}} {
        #--- horizontally join two strimjes
        set si [expand $si1 0 [util::max [height $si1] [height $si2]]]
        set res {}
        foreach line1 [lines $si] line2 [lines $si2]  {
            lappend res "$line1$pad$line2"
        }
        join $res \n
    }
    proc expand {si {w 0} {h 0}} {
        #--- turn a strimj to specified dim. and equal-length lines
        if {!$w} {set w [width  $si]}
        if {!$h} {set h [height $si]}
        set res {}; set n 0; set filler " "
        foreach line [lines $si] {
            lappend res [util::pad line $w $filler]
            incr n
        }
        set filline [string repeat $filler $w]
        while {$n<$h} {lappend res $filline; incr n}
        join $res \n
    }
    proc flip {si axis} {
        switch -- $axis {
        x       {join [util::lrevert [lines $si]] \n}
        y       {join [util::map util::revert [lines [expand $si]]] \n}
        default {error "bad axis $axis: must be x or y"}
        }
    }
    proc font {font data} {
        #--- add one or more images to the font database
        variable Font
        regsub -all {\\} $data {\\\\} data
        foreach {labels si} $data {
            foreach label $labels {
                set label [subst -nocommands -novariables $label]
                set Font($font,$label) ""
            }
            foreach line [lines $si] {
                foreach label $labels pixels $line {
                    set label [subst -nocommands -novariables $label]
                    append Font($font,$label) [string map {. " "} $pixels]\n
                }
            }
        }
    }
    proc height si {llength [lines $si]}
    proc lines  si {split [string trim $si \n] \n}
    proc new   {width height {color " "}} {zoom $color $width $height}
    proc photo {si {usermap ""}} {
        variable defaultColors
        array set map [concat $defaultColors $usermap]
        set img [image create photo -height [height $si] -width [width $si]]
        set y 0
        foreach line [lines $si] {
            set x 0
            foreach char [split $line ""] {
                if {$char!=" "} {
                    if {![info exist map($char)]} {set map($char) black}
                    $img put $map($char) -to $x $y
                }
                incr x       
            }
            incr y
        }
        set img
    }
    proc rotate {si angle} {
        switch -- $angle {
        90      {rot90 $si}
        180     {flip [flip $si x] y}
        270     {rot90 [rotate $si 180]}
        default {error "bad angle $angle: must be 90|180|270"}
        }
    }
    proc rot90 si {
        set cols [util::range [width $si]]
        foreach line [lines [expand $si]] {
            foreach col $cols char [split $line ""] {
                append $col $char
            }
        }
        join [util::lrevert [util::lget $cols]] \n
    }
    proc shear {si {gradient 3}} {
        set lines [lines $si]
        set h [llength $lines]
        set bias [expr {$h-($h/$gradient)*$gradient}]
        set res {}
        set n 0
        foreach line $lines {
            set dx [expr {($gradient>0?($h-$n-1):$bias-$n)/$gradient}]
            append res [string repeat . $dx]$line\n
            incr n
        }
        set res
    }
    proc subsample {si {xfac 2} {yfac 0}} {
        if {!$yfac} {set yfac $xfac}
        set ilist [string repeat "i " $yfac]
        set res {}
        foreach $ilist [lines $si] {
            lappend res [subsampleLine $i $xfac]
        }
        join $res \n
    }
    proc subsampleLine {string xfac} {
        set ilist [string repeat "i " $xfac]
        set res ""
        foreach $ilist [split $string ""] {append res $i}
        set res
    }
    proc text {string args} {
        #--- render a string into a strimj
        array set opt [::concat {-font - -pad " "} $args]
        set si [char [string index $string 0] $opt(-font)]
        foreach c [split [string range $string 1 end] ""] {
            set si [concat $si [char $c $opt(-font)] $opt(-pad)]
        }
        set si
    }
    proc width si {util::max [util::map "string length" [lines $si]]}
    proc xbm si {
        set si [string map {" " 0 . 0} [expand $si]]
        set lines [lines $si]
        set width [string length [lindex $lines 0]]
        set height [llength $lines]
        set bytes {}
        foreach line $lines {
            regsub -all {[^0]} $line 1 line ;# black pixel
            foreach bin [split [binary format b* $line] ""] {
                    lappend bytes [scan $bin %c]
            }
        }
        set    res "#define i_width $width\n#define i_height $height\n"
        append res "static char i_bits\[\] = {\n[join $bytes ,]\n}"
    }
    proc zoom {si {xfac 2} {yfac 0}} {
        #--- negative zoom factors imply flipping
        if {$xfac<0} {
            set si [flip $si x]
            set xfac [expr {-$xfac}]
        }
        if {$yfac<0} {
            set si [flip $si y]
            set yfac [expr {-$yfac}]
        }
        if {$xfac==1 && $yfac==1} {return $si}
        if {!$yfac} {set yfac $xfac}
        #--- zoom factors<1 imply subsampling
        if {$xfac<1 && $yfac<1} {
            set xfac [expr {round(1./$xfac)}]
            set yfac [expr {round(1./$yfac)}]
            return [subsample $si $xfac $yfac]
        }
        set res {}
        foreach line [lines $si] {
            foreach - [util::range $yfac] {
                lappend res [util::strmul $line $xfac]
            }
        }
        join $res \n
    }

    set Font(default) 5x10
    font 5x10 {
    {{ }} ...
    {A B C D E F G H I J K} "
        ..@.. @@@@  .@@@. @@@   @@@@@ @@@@@ .@@@. @...@ @@@ ....@ @...@
        .@.@. @...@ @...@ @..@  @     @     @...@ @...@ .@  ....@ @..@
        @...@ @...@ @     @...@ @     @     @     @...@ .@  ....@ @.@
        @...@ @@@@. @     @...@ @@@@  @@@@  @..@@ @@@@@ .@  ....@ @@
        @@@@@ @...@ @     @...@ @     @     @...@ @...@ .@  ....@ @.@
        @...@ @...@ @     @...@ @     @     @...@ @...@ .@  ....@ @..@
        @...@ @...@ @...@ @..@  @     @     @...@ @...@ .@  @...@ @...@
        @...@ @@@@  .@@@  @@@   @@@@@ @     .@@@  @...@ @@@ .@@@  @....@"
    {L M N O P Q R S T U} "
        @     @...@ @....@ .@@@. @@@@  .@@@. @@@@  .@@@. @@@@@ @...@
        @     @@.@@ @@...@ @...@ @...@ @...@ @...@ @...@ ..@   @...@
        @     @.@.@ @@...@ @...@ @...@ @...@ @...@ @     ..@   @...@
        @     @.@.@ @.@..@ @...@ @...@ @...@ @...@ .@@.  ..@   @...@
        @     @...@ @..@.@ @...@ @@@@  @...@ @@@@  ...@  ..@   @...@
        @     @...@ @..@@@ @...@ @     @.@.@ @.@   ....@ ..@   @...@  
        @     @...@ @...@@ @...@ @     @..@  @..@  @...@ ..@   @...@
        @@@@@ @...@ @....@ .@@@  @     .@@.@ @...@ .@@@. ..@   .@@@."
    {V W X Y Z} "
        @...@ @...@ @...@ @...@ @@@@@@
        @...@ @...@ @...@ @...@ .....@
        @...@ @...@ @...@ .@.@. ....@
        @...@ @.@.@ .@.@. .@.@  ...@
        .@.@. @.@.@ ..@.. ..@   ..@.
        .@.@. @@.@@ .@.@. ..@   .@..
        .@.@. @@.@@ @...@ ..@   @...
        ..@.. @...@ @...@ ..@   @@@@@@"
    {0 1 2 3 4 5 6 7 8 9} "
        .@@@. ..@.. .@@@. .@@@. .@.@. @@@@@ .@@@. @@@@@ .@@@. .@@@.
        @...@ .@@.. @...@ @...@ .@.@. @     @...@ ....@ @...@ @...@
        @@..@ @.@.. ....@ ....@ @..@. @     @     ...@  @...@ @...@
        @.@.@ ..@.. ...@  ..@@  @..@. @.@@  @@@@  ...@  .@@@. @...@
        @..@@ ..@.. ..@   ....@ @@@@@ @@..@ @...@ ..@   @...@ .@@@@
        @...@ ..@.. .@    ....@ ...@  ....@ @...@ ..@   @...@ ....@
        @...@ ..@.. @.    @...@ ...@  @...@ @...@ ..@   @...@ @...@
        .@@@. .@@@. @@@@@ .@@@  ...@  .@@@  .@@@. ..@   .@@@. .@@@."
    {a b c d e f h i k l m n} "
        ..... @.... ..... ....@ ..... .@@ @     @ @     @ .       .
        ..... @.... ..... ....@ ..... .@  @     . @     @ .       .
        .@@@. @.@@  .@@@. .@@.@ .@@@. .@. @.@@  @ @..@  @ @@@.@@. @.@@
        ....@ @@..@ @...@ @..@@ @...@ @@@ @@..@ @ @.@   @ @..@..@ @@..@
        .@@@@ @...@ @     @...@ @@@@@ .@  @...@ @ @@    @ @..@..@ @...@
        @...@ @...@ @.... @...@ @.... .@  @...@ @ @.@   @ @..@..@ @...@
        @..@@ @...@ @...@ @..@@ @...@ .@  @...@ @ @..@  @ @..@..@ @...@
        .@@.@ @@@@. .@@@. .@@.@ .@@@. .@  @...@ @ @...@ @ @..@..@ @...@"
    {o r s t u v w x z} "
        ..... .    .     .@. .     .     .         .     .
        ..... .    .     .@. .     .     .         .     .
        .@@@. @.@@ .@@@. @@@ @...@ @...@ @...@...@ @...@ @@@@@
        @...@ @@   @...@ .@. @...@ @...@ @...@...@ .@.@. ...@.
        @...@ @    .@@   .@. @...@ .@.@. .@.@.@.@  ..@.. ..@..
        @...@ @    ...@. .@. @...@ .@.@. .@.@.@.@  .@.@. .@...
        @...@ @    @...@ .@  @..@@ ..@   ..@...@   @...@ @  
        .@@@. @    .@@@. .@. .@@.@ ..@.. ..@...@   @...@ @@@@@"
    {g j p q y} "
        .     .@ .     .     .
        .     .. .     .     .
        .@@.@ .@ @.@@. .@@.@ @...@
        @..@@ .@ @@..@ @..@@ @...@
        @...@ .@ @...@ @...@ @...@
        @...@ .@ @...@ @...@ .@.@.
        @..@@ .@ @...@ @...@ .@.@.
        .@@.@ .@ @@@@. .@@@@ ..@..
        ....@ .@ @     ....@ .@...
        .@@@  @  @     ....@ @"
    {! \" # \$ % ' ( ) + , - . /} "
        @ @.@ .@.@. ..@.. .@...@ @ ..@ @   ..... .. ..... . ...@
        @ @.@ .@.@. .@@@  @.@..@ @ .@  .@  ..... .. ..... . ...@
        @ .   @@@@@ @.@.@ .@..@  . @   ..@ ..@.. .. ..... . ..@
        @ .   .@.@  @.@   ...@   . @   ..@ ..@.. .. ..... . ..@
        @ .   .@.@. .@@@. ..@..  . @   ..@ @@@@@ .. @@@@@ . .@
        @ .   @@@@@ ..@.@ .@..@. . @   ..@ ..@.. .. ..... . .@
        . .    @.@  @.@.@ @..@.@ . .@  .@  ..@.. @@ ..... . @
        @ .    @.@   @@@  @...@  . ..@ @   ..... @. ..... @ @"
    {? \{ \} \\} "
        .@@@. ..@@ @@   @
        @...@ .@   ..@  @
        ....@ .@   ..@  .@
        ...@. @    ...@ .@
        ..@.. .@   ..@  ..@
        ..@.. .@   ..@  ..@
        ..... .@   ..@  ...@
        ..@.. ..@@ @@   ...@"
    }
    font cute {
        {a b c} {
        ..      ._      .
        ..      |.|     .
        ..__._  |.|._   ..___
        ./._`.| |.′_.\  ./.__\
        |.(_|.| |.|_).| |.(__
        .\__,_| |_,__/  .\___/
    }
    }
    font demo {
        fx "
        ...@
        ..@@@
        .@@@@@
        @@@@@@@
        ...@
        ...@
        ...@
        @@@@@@@
        .@@@@@
        ..@@@
        ...@"
        fy "
        ...@...@
        ..@@...@@
        .@@@...@@@
        @@@@@@@@@@@
        .@@@...@@@
        ..@@...@@
        ...@...@"
        rot "
        ...@
        ..@@
        .@@@
        @@@@@@@
        .@@@...@
        ..@@...@
        ...@...@
        .......@"
    }
    set Font(unknown) $Font(5x10,?)
} ;# end namespace strimj
 
 # utilities of general use, may some day go into their own package
 namespace eval util {
    proc lget varlist {
        #-- turn a list of var.names in caller's scope to their values
        set res {}
        foreach var $varlist {lappend res [uplevel 1 set $var]}
        set res
    }
    proc lrevert list {
        #--- e.g. lrevert {a b c} => c b a
        set res {}
        for {set i [expr {[llength $list]-1}]} {$i>=0} {incr i -1} {
            lappend res [lindex $list $i]
        }
        set res
    }
    proc map {func list} {
        #--- apply a function to each element of a list
        set res {}
        foreach i $list {lappend res [eval $func [list $i]]}
        set res
    }
    proc max args {
        if {[llength $args]==1} {set args [lindex $args 0]}
        lindex [lsort -real -decreasing $args] 0
    }
    proc pad {_string length filler} {
        upvar $_string string
        set n [expr {$length-[string length $string]}]
        append string [string repeat $filler $n]
    }
    proc range n {
        #--- produce a list from 0 to n-1 (for unrolling for's) 
        set res {}
        for {set i 0} {$i<$n} {incr i} {lappend res $i}
        set res
    }
    proc revert string {join [lrevert [split $string ""]] ""}
    proc strmul {string factor} {
        #--- multiply a string, e.g. strmul ABC 3 => AAABBBCCC
        set res ""
        foreach char [split $string ""] {
            for {set i 0} {$i<$factor} {incr i} {
                append res $char
            }
        }
        set res
    }
 }

 #--- test and demo code... 
 if {[file tail [info script]]==[file tail $argv0]} {
    proc strimj::demo {} {
        variable Font
        regsub -all {[^ ]+,} [array names Font *,?] "" abc
        #set ::demoimg [text [join [lsort $abc] ""]]
        set ::demoimg [text "Abc 123" -background white]
        trace var ::demoimg w {.l config -image [strimj::bitmap $::demoimg] ;#}
        label .info -textvar ::info
        frame .f
        label .f.l -image [photo [zoom ry\ngb 12]]
        button .f.fx -image [bitmap [char fx]] -command {
            tell [time {set demoimg [strimj::flip $::demoimg x]}]
        }
        button .f.fy -image [bitmap [char fy]] -command {
            tell [time {set demoimg [strimj::flip $::demoimg y]}]
        }
        button .f.rot -image [bitmap [char rot]] -command {
            tell [time {set demoimg [strimj::rot90 $::demoimg]}]
        }
        button .f.zoom -text "+" -command {
            tell [time {set demoimg [strimj::zoom $::demoimg]}]
        }
        button .f.unzoom -text " - " -command {
            tell [time {set demoimg [strimj::subsample $::demoimg]}]
        }
        button .f.slant -text "/" -command {
            tell [time {set demoimg [strimj::shear $::demoimg 3]}]
        }
        button .f.slant- -text "\\" -command {
            tell [time {set demoimg [strimj::shear $::demoimg -3]}]
        }
        bind .f.unzoom <3> {tell [time {set demoimg $demoimg}]}
        eval pack [winfo children .f] -side left -fill both -ipadx 2
        label .l -image [bitmap $::demoimg] -bg white
        pack .info .f .l
    }
     proc tell time {
        set img $::demoimg
        set w [strimj::width $img]
        set h [strimj::height $img]
        set ::info "$w*$h=[expr {$w*$h}]: [expr {[lindex $time 0]/1000000.}]"
    }
    bind . <F12> "console show"
    strimj::demo
 }
