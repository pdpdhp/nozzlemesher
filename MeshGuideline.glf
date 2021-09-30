# =============================================================
# This script is written to generate structured multi-block
# grid for a nozzle profile with respect to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc MGuideLine {ref_lev guidedir} {
	
	global ypg dsg grg chord_sg stnum_sg nwaves_sg pspeed_sg
	
	#Reading Meshing Guidline
	set fp [open "$guidedir/grid_specification.txt" r]

	set i 0
	while {[gets $fp line] >= 0} {
		set g_spec($i) {}
			foreach elem $line {
				lappend g_spec($i) [scan $elem %e]
			}
		incr i
	}
	close $fp

	for {set j 1} {$j<$i} {incr j} {
		lappend y_p [lindex $g_spec($j) 0]
		lappend d_s [lindex $g_spec($j) 1]
		lappend gr [lindex $g_spec($j) 2]
		lappend chord_s [lindex $g_spec($j) 3]
		lappend stnum_s [lindex $g_spec($j) 4]
		lappend nwaves_s [lindex $g_spec($j) 5]
		lappend pspeed_s [lindex $g_spec($j) 6]

	}

	set NUM_REF [llength $y_p]

	if {$ref_lev<$NUM_REF} {
		set ypg [lindex $y_p $ref_lev]
		set dsg [lindex $d_s $ref_lev]
		set grg [lindex $gr $ref_lev]
		set chord_sg [lindex $chord_s $ref_lev]
		set stnum_sg [lindex $stnum_s $ref_lev]
		set nwaves_sg [lindex $nwaves_s $ref_lev]
		set pspeed_sg [lindex $pspeed_s $ref_lev]

	} else {
		puts "PLEASE SELECT THE RIGHT REFINEMENT LEVEL ACCORDING TO YOUR GUIDELINE FILE: ref_lev"
		exit -1
	}

}
