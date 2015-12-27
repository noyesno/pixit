
pack [canvas .c] -fill both -expand 1

set x 32 ; set y 32
foreach name {
error
gray75
gray50
gray25
gray12
hourglass
info
questhead
question
warning
document
stationery
edition
application
accessory
folder
pfolder
trash
floppy
ramdisk
cdrom
preferences
querydoc
stop
note
caution
} {
 catch {
   .c create bitmap $x $y -bitmap $name
 }
 incr x 16

 if {$x%96==0} {
   incr y 16
   set  x 32
 }
}
