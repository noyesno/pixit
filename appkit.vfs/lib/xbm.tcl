
# From: http://wiki.tcl.tk/6166
# XBM = X Bitmap
# XBD = X Bitmap Data
# XBT = X Bitmap Text
#
# XBM File Format:
#   1. a short header specifying image height and width
#   2. a series (enclosed in braces) of "big-endian" hexadecimal codes, 
#      - separated by semicolons and spaces
#      - representing "little-endian" binary data.



proc xbmtoxbd {xbm} {
        global xbd_data
        set xbd_data ""

        # Open XBM file:
        set fileid [open $xbm "r"]
        set newxbm [read $fileid]
        close $fileid

        # Get image width and height from XBM header:
        set onbrace [string first "\{" $newxbm]
        set onrang [string range $newxbm 0 $onbrace]
        set onlines [split $onrang "\n"]
        set goxbox 0
        foreach line $onlines {
                set deflin [split $line {" "_}]
                if { [lindex $deflin 0] == "#define" } {
                        set widorhi [lindex $deflin "end-1"]
                        if { $widorhi == "width" } {
                                set bimwid [lindex $deflin end]
                                set eighthwid [expr $bimwid / 8.0]
                                set eighto [split $eighthwid "."]
                                if { [lindex $eighto end] == 0 } {
                                        set xbd_half [lindex $eighto 0]
                                } else {
                                        set xbd_half [expr [lindex $eighto 0] + 1]
                                }
                                set xbd_width [expr $xbd_half*2]
                        } elseif { $widorhi == "height" } {
                                set img_ht [lindex $deflin end]
                        }
                }
                if { [string equal $xbd_width ""] < 1 && [string equal \
                        $img_ht ""] < 1 } {
                        break
                }
        }

        # Strip away inessentials from bitmap data:
        set firstox [string first "0x" $newxbm]
        set xbmtext [string range $newxbm $firstox end]
        set xbmtext [string map {
                "0x" "" "," "" " " "" "\}" "" ";" "" "\n" ""
                } $xbmtext]
        for { set x 0 } { $x <= $img_ht } { incr x } {
                set linestar [expr $xbd_width * $x]
                set linend [expr $linestar + $xbd_width -1]
                set xbdlin [string range $xbmtext $linestar $linend]
                append xbd_data "$xbdlin\n"
        }
}


proc xbdtoxbt {xbd} {
        global xbt_text
        set xbt_text [string map {
                00 00000000 01 10000000 02 01000000 03 11000000 \
                04 00100000 05 10100000 06 01100000 07 11100000 \
                08 00010000 09 10010000 0a 01010000 0b 11010000 \
                0c 00110000 0d 10110000 0e 01110000 0f 11110000 \
                10 00001000 11 10001000 12 01001000 13 11001000 \
                14 00101000 15 10101000 16 01101000 17 11101000 \
                18 00011000 19 10011000 1a 01011000 1b 11011000 \
                1c 00111000 1d 10111000 1e 01111000 1f 11111000 \
                20 00000100 21 10000100 22 01000100 23 11000100 \
                24 00100100 25 10100100 26 01100100 27 11100100 \
                28 00010100 29 10010100 2a 01010100 2b 11010100 \
                2c 00111100 2d 10110100 2e 01110100 2f 11110100 \
                30 00001100 31 10001100 32 01001100 33 11001100 \
                34 00101100 35 10101100 36 01101100 37 11101100 \
                38 00011100 39 10011100 3a 01011100 3b 11011100 \
                3c 00111100 3d 10111100 3e 01111100 3f 11111100 \
                40 00000010 41 10000010 42 01000010 43 11000010 \
                44 00100010 45 10100010 46 01100010 47 11100010 \
                48 00010010 49 10010010 4a 01010010 4b 11010010 \
                4c 00110010 4d 10110010 4e 01110010 4f 11110010 \
                50 00001010 51 10001010 52 01001010 53 11001010 \
                54 00101010 55 10101010 56 01101010 57 11101010 \
                58 00011010 59 10011010 5a 01011010 5b 11011010 \
                5c 00111010 5d 10111010 5e 01111010 5f 11111010 \
                60 00000110 61 10000110 62 01000110 63 11000110 \
                64 00100110 65 10100110 66 01100110 67 11100110 \
                68 00010110 69 10010110 6a 01010110 6b 11010110 \
                6c 00110110 6d 10110110 6e 01110110 6f 11111110 \
                70 00001110 71 10001110 72 01001110 73 11001110 \
                74 00101110 75 10101110 76 01101110 77 11101110 \
                78 00011110 79 10011110 7a 01011110 7b 11011110 \
                7c 00111110 7d 10111110 7e 01111110 7f 11111110 \
                80 00000001 81 10000001 82 01000001 83 11000001 \
                84 00100001 85 10100001 86 01100001 87 11100001 \
                88 00010001 89 10010001 8a 01010001 8b 11010001 \
                8c 00110001 8d 10110001 8e 01110001 8f 11110001 \
                90 00001001 91 10001001 92 01001001 93 11001001 \
                94 00101001 95 10101001 96 01101001 97 11101001 \
                98 00011001 99 10011001 9a 01011001 9b 11011001 \
                9c 00111001 9d 10111001 9e 01111001 9f 11111001 \
                a0 00000101 a1 10000101 a2 01000101 a3 11000101 \
                a4 00100101 a5 10100101 a6 01100101 a7 11100101 \
                a8 00010101 a9 10010101 aa 01010101 ab 11010101 \
                ac 00110101 ad 10110101 ae 01110101 af 11110101 \
                b0 00001101 b1 10001101 b2 01001101 b3 11001101 \
                b4 00101101 b5 10101101 b6 01101101 b7 11101101 \
                b8 00011101 b9 10011101 ba 01011101 bb 11011101 \
                bc 00111101 bd 10111101 be 01111101 bf 11111101 \
                c0 00000011 c1 10000011 c2 01000011 c3 11000011 \
                c4 00100011 c5 10100011 c6 01100011 c7 11100011 \
                c8 00010011 c9 10010011 ca 01010011 cb 11010011 \
                cc 00110011 cd 10110011 ce 01110011 cf 11110011 \
                d0 00001011 d1 10001011 d2 01001011 d3 11001011 \
                d4 00101011 d5 10101011 d6 01101011 d7 11101011 \
                d8 00011011 d9 10011011 da 01011011 db 11011011 \
                dc 00111011 dd 10111011 de 01111011 df 11111011 \
                e0 00000111 e1 10000111 e2 01000111 e3 11000111 \
                e4 00100111 e5 10100111 e6 01100111 e7 11100111 \
                e8 00010111 e9 10010111 ea 01010111 eb 11010111 \
                ec 00110111 ed 10110111 ee 01110111 ef 11110111 \
                f0 00001111 f1 10001111 f2 01001111 f3 11001111 \
                f4 00101111 f5 10101111 f6 01101111 f7 11101111 \
                f8 00011111 f9 10011111 fa 01011111 fb 11011111 \
                fc 00111111 fd 10111111 fe 01111111 ff 11111111 \
        } $xbd]
}

