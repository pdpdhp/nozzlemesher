set scriptDir [file dirname [info script]]

set exportDir [file join $scriptDir grids]
file mkdir $exportDir
set res_lev 4
set unmarked lev4_7m528k.su2
set interfaced lev4_7m528k_FWHinterface.su2
set gridunmarked lev4_7m528k_FWHmarked.su2

set symsep1 [string repeat = 70]
set symsep2 [string repeat - 70]

file delete -force "$exportDir/$gridunmarked"

puts "APPENDING FWH MARKER TO $unmarked."
puts $symsep1

set nmmarked $gridunmarked

set unsline [exec sed -n "10,$ { /NPOIN/= }" $exportDir/$unmarked]
set nunpoints 0

set msline [exec sed -n "10,$ { /NPOIN/= }" $exportDir/$interfaced]
set nmpoints 0
set mmline [exec sed -n "10,$ { /MARKER_TAG= FWHinterface/= }" $exportDir/$interfaced]
set mmpoints 0

set fpmod [open "$exportDir/$unmarked" r]
set i 0
set cline 1
set gx_modpt [list]
set gy_modpt [list]
set gz_modpt [list]
set g_modi [list]
while {[gets $fpmod line] >= 0} {
	if { $cline == $unsline } {
		set nunpoints [lsearch -all -inline -not $line NPOIN*]
	}
	
	if { $cline > $unsline && $cline <= [expr {$unsline+$nunpoints}] } {
		lappend g_modpt $line
	incr i
	}
	incr cline
}
close $fpmod
puts $symsep2
puts "READING MESH WITHOUT FWH MARKER/INTERFACE: $unmarked"

set fpmrk [open "$exportDir/$interfaced" r]
set j 0
set q 0
set cline2 1
array set g_mrk {}
set g_mrkpt [list]
while {[gets $fpmrk line] >= 0} {
	if { $cline2 == $msline } {
		set nmpoints [lsearch -all -inline -not $line NPOIN*]
	}
	if { $cline2 == [expr {$mmline+1}] } {
		set mmpoints [lsearch -all -inline -not $line MARKER_ELEMS*]
	}
	
	if { $cline2>$msline && $cline2<= [expr {$msline+$nmpoints}]} {
			lappend g_mrkpt [string range $line 0 74]
	incr q
	}
	
	if { $cline2 > [expr {$mmline+1}] && $cline2 <= [expr {$mmline+$mmpoints+1}] } {
		foreach elem $line {
			lappend g_mrk($j) [scan $elem %12d]
		}
	incr j
	}
	
	incr cline2
}
close $fpmrk
puts $symsep2
puts "READING MESH WITH FWH INTERFACE: $interfaced"

set ifcount 0
array set xyz_mrkpt {}
for {set m 0} {$m < [array size g_mrk]} {incr m} {
	for {set p 1} {$p < 5} {incr p} {
				lappend xyz_mrkpt($m) [lindex $g_mrkpt [expr int([lindex $g_mrk($m) $p])]]
				incr ifcount
	}
}

set FWHMarker_elems [array size xyz_mrkpt]

file copy "$exportDir/$unmarked" "$exportDir/$nmmarked" 

set fexmod [open "$exportDir/$nmmarked" a]
puts $fexmod "MARKER_TAG= FWHMarker"
puts $fexmod "MARKER_ELEMS= $FWHMarker_elems"
set w1 5
array set xyz_modpt {}
array set g_mod {}

puts $symsep2
puts "WRITING MESH WITH FWH MARKER: $nmmarked"
puts "warning: Please note this process could be time consuming!"

for {set m 0} {$m < $FWHMarker_elems} {incr m} {
	for {set p 0} {$p < 4} {incr p} {
		lappend xyz_modpt($m) [lsearch -inline $g_modpt [lindex $xyz_mrkpt($m) $p]*]
		lappend g_mod($m) [string trim [string range [lindex $xyz_modpt($m) $p] 75 83]]
	}
	puts $fexmod [format " 9  %*d %*d %*d %*d" $w1 [lindex $g_mod($m) 0] $w1 [lindex $g_mod($m) 1] $w1 [lindex $g_mod($m) 2] $w1 [lindex $g_mod($m) 3]]
}
close $fexmod

puts "info: $FWHMarker_elems ELEMENTS ARE MARKED FROM $unmarked"
puts $symsep2
puts "$nmmarked GRID WITH FWH MARKER EXPORTED FOR LEVEL $res_lev"
puts $symsep1
puts "COMPLETE!"
