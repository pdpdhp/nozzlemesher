# =============================================================
# This script is written to generate structured multi-block
# grid for a nozzle profile with respect to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

package require PWI_Glyph 3.18.3

proc Config_Prep { } {

	global defset guidelineDir MeshParameters MparafullFilename res_lev
	
	if { $MeshParameters != "" } {
		puts "GRID VARIABLES ARE SET BY $MeshParameters"
		set defset [ParamDefualt $MparafullFilename]
	} else {
		puts "DEFAULT GRID VARIABLES ARE SET BY defaultMeshParameters.glf"
	}
	
	#updating gridflow.py with new sets of variables
	GridFlowprop_Update [lrange [lindex $defset 0] end-6 end] [lrange [lindex $defset 1] end-6 end] $guidelineDir
	
	MGuideLine $res_lev $guidelineDir
}

proc CAD_Read {nzzpf} {
	
	global cae_solver GRD_TYP nprofile nx_node ny_node
	
	upvar 1 symsepdd asep
	#grid tolerance
	pw::Grid setNodeTolerance 1.0e-10
	pw::Grid setConnectorTolerance 1.0e-10
	pw::Grid setGridPointTolerance 1.0e-10

	pw::Connector setCalculateDimensionMaximum 100000
	pw::Application setCAESolver $cae_solver 2
	
	if {[string compare $GRD_TYP STR]==0} {
		puts "STRUCTURED MULTIBLOCK GRID SELECTED."
		puts $asep
	} 
	
	if { $nprofile != "" } {
		set fpmod [open $nzzpf r]

		while {[gets $fpmod line] >= 0} {
			lappend nx_node [scan [string range $line 0 10] %12f]
			lappend ny_node [scan [string range $line 10 19] %12f]
		}

		close $fpmod
		
		puts "NOZZLE PROFILE IMPORTED."
		puts $asep
	} else {
		puts "PLEASE INDICATE NOZZLE PROFILE AS INPUT."
	}
	

}

proc Nzz_Geo { } {
	
	global nx_node ny_node nozzUpperCurve nozzLowerCurve nozzTeCurve nozzLowerCurve_sp
	
	# NOZZLE GEOMETRY
	# -----------------------------------------------
	# Create upper surface
	set nozzUpperPts [pw::SegmentSpline create]
	$nozzUpperPts setSlope Free

	for {set i 0} {$i <= 191} {incr i} {
		$nozzUpperPts addPoint [list [lindex $nx_node $i] [lindex $ny_node $i] 0]
	}

	set nozzUpperCurve [pw::Curve create]

	$nozzUpperCurve addSegment $nozzUpperPts

	# Create lower surface
	set nozzLowerPts [pw::SegmentSpline create]
	$nozzLowerPts setSlope Free

	for {set i 192} {$i < 624} {incr i} {
		$nozzLowerPts addPoint [list [lindex $nx_node $i] [lindex $ny_node $i] 0]
	}

	set nozzLowerCurve [pw::Curve create]
	$nozzLowerCurve addSegment $nozzLowerPts


	# Create thickness
	set nozzTePts [pw::SegmentSpline create]
	$nozzTePts setSlope Free

	for {set i 191} {$i <= 192} {incr i} {
		$nozzTePts addPoint [list [lindex $nx_node $i] [lindex $ny_node $i] 0]
	}

	set nozzTeCurve [pw::Curve create]

	$nozzTeCurve addSegment $nozzTePts

	#--------------------------------------------------

	set nozzLowerCurve_sp [$nozzLowerCurve split [$nozzLowerCurve getParameter -X [lindex $nx_node 0]]]

}

proc FWH_Update { } {
	
	global scriptDir res_lev gridname gridnameFWHint gridnameFWHmrk
	
	upvar 1 symsep asep
	
	#updating FWHMaker generator with new mesh infos

	exec sed -i "/set res_lev/d" $scriptDir/FWHMarker.tcl
	exec sed -i "4 a set res_lev $res_lev" $scriptDir/FWHMarker.tcl

	exec sed -i "/set unmarked/d" $scriptDir/FWHMarker.tcl
	exec sed -i "5 a set unmarked $gridname.su2" $scriptDir/FWHMarker.tcl

	exec sed -i "/set interfaced/d" $scriptDir/FWHMarker.tcl
	exec sed -i "6 a set interfaced $gridnameFWHint.su2" $scriptDir/FWHMarker.tcl

	exec sed -i "/set gridunmarked/d" $scriptDir/FWHMarker.tcl
	exec sed -i "7 a set gridunmarked $gridnameFWHmrk.su2" $scriptDir/FWHMarker.tcl
	
	set dashes [string repeat - 70]
	
	puts $dashes
	puts "GRID INFO FOR $gridname IS EXPORTED TO FWHMarker.tcl!"
	puts $asep

}

proc NZZMESHER {} {
	
	global MeshParameters nprofile NprofullFilename MparafullFilename
	global res_lev ypg dsg grg chord_sg
	global scriptDir fexmod defset
	
	set symsep [string repeat = 105]
	set symsepd [string repeat . 105]
	set symsepdd [string repeat - 105]
	
	if { $NprofullFilename == "" } {
		if [pw::Application isInteractive] {
			set NprofullFilename [tk_getOpenFile]
		}
	}

	if { ! [file readable $NprofullFilename] } {
		puts "WITHOUT NOZZLE COORDINATES AS INPUT THIS SCRIPT DOESN'T WORK."
		puts "NOZZLE COORDINATES: $nprofile does not exist or is not readable"
		exit -1
	}
	
	
	#----------------------------------------------------------------------------
	#READING AND UPDATING GRID PARAMETERS AND VARIABLES
	Config_Prep

	puts $symsepdd
	puts "GRID GUIDELINE: Level: $res_lev | Y+: $ypg | Delta_S(m): $dsg | GR: $grg | Nozzle_Spacing(m): $chord_sg"
	puts $symsep
	
	set meshparacol [lindex $defset 1]
	set defParas [lindex $defset 0]
	
	set time_start [pwu::Time now]

	#----------------------------------------------------------------------------
	#READING CAD MODEL
	CAD_Read $NprofullFilename

	#----------------------------------------------------------------------------
	#CREATING NOZZLE PROFILE
	Nzz_Geo

	set blkexam [pw::Examine create BlockVolume]

	#----------------------------------------------------------------------------
	#GENERATING THE MESH
	set nzzblks [Nozzle_Mesh]

	#----------------------------------------------------------------------------
	set fexmod [open "$scriptDir/CAE_export.out" w]

	#----------------------------------------------------------------------------
	#CAE EXPORT
	CAE_Export $nzzblks

	#----------------------------------------------------------------------------
	#FWH UPDATER
	FWH_Update

	pw::Display saveView 1 [list {0.0 0.0 0.0} {-18.37 -6.89 0.0} {0.14 -1.0 -0.06} 50.40 111.60]
	pw::Display recallView 1

	set time_end [pwu::Time now]
	set runtime [pwu::Time subtract $time_end $time_start]
	set tmin [expr int([lindex $runtime 0]/60)]
	set tsec [expr [lindex $runtime 0]%60]
	set tmsec [expr int(floor([lindex $runtime 1]/1000))]

	puts $fexmod [string repeat - 50]
	puts $fexmod "runtime: $tmin min $tsec sec $tmsec ms" 
	puts $fexmod [string repeat - 50]
	close $fexmod

	puts "GRID INFO WRITTEN TO CAE_export.out"
	puts $symsep
	puts "COMPLETE!"
	
	exit
}

#-------------------------------------- RESET APPLICATION--------------------------------------

pw::Application reset
pw::Application clearModified

set scriptDir [file dirname [info script]]
set guidelineDir [file join $scriptDir guideline]

source [file join $scriptDir "ParamRead.glf"]
source [file join $guidelineDir "GridParamUpdate.glf"]
source [file join $scriptDir "MeshGuideline.glf"]
source [file join $scriptDir "nozz_mesh.glf"]
source [file join $scriptDir "cae_exporter.glf"]

set defset [ParamDefualt [file join $scriptDir "defaultMeshParameters.glf"]]

set MeshParameters ""
set nprofile ""

set MeshParameters ""
set nprofile ""
set NprofullFilename ""
set MparafullFilename ""

if [pw::Application isInteractive] {

	pw::Script loadTK
	
	set wkrdir [pwd]

	proc meshparametersgui { } {

		global wkrdir MeshParameters MparafullFilename
		cd $wkrdir
		
		if { $MeshParameters != "" } {
		
			file exists $MparafullFilename
			puts "Input parameters: $MeshParameters"

		} else {

			set types {
 				{{GLYPH Files}  {.glf}}
 				{{All Files}      *   }
 			}

			set initDir $::wkrdir
			set MparafullFilename [tk_getOpenFile -initialdir $initDir -filetypes $types]
			set MeshParameters [file tail $MparafullFilename]
		}
	}

	proc nzzprofile { } {

		global wkrdir nprofile NprofullFilename
		cd $wkrdir

		if { $NprofullFilename != "" } {

			file exists $NprofullFilename
			puts "Input nozzle coordinates: $nprofile"

		} else {

			set types {
				{{Text Files}  {.txt}}
				{{All Files}      *  }
			}
			
			set initDir $::wkrdir
			set NprofullFilename [tk_getOpenFile -initialdir $initDir -filetypes $types]
			set nprofile [file tail $NprofullFilename]
		}
	}

	wm title . "NOZZLE MESHER"
	grid [ttk::frame .c -padding "5 5 5 5"] -column 0 -row 0 -sticky nwes
	grid columnconfigure . 0 -weight 1; grid rowconfigure . 0 -weight 1
	grid [ttk::labelframe .c.lf -padding "5 5 5 5" -text "SELECT MESH PARAMETERS"]
	grid [ttk::button .c.lf.mfl -text "MESHING  INPUT" -command \
					meshparametersgui]                           -row 1 -column 1 -sticky e
	grid [ttk::entry .c.lf.mfe -width 60 -textvariable MeshParameters]           -row 1 -column 2 -sticky e
	grid [ttk::button .c.lf.ptl -text "NOZZLE PROFILE" -command nzzprofile]      -row 2 -column 1 -sticky e
	grid [ttk::entry .c.lf.pte -width 60 -textvariable nprofile]                 -row 2 -column 2 -sticky e
	grid [ttk::button .c.lf.gob -text "NOZZLE MESH" -command NZZMESHER]          -row 3 -column 2 -sticky e
	
	foreach w [winfo children .c.lf] {grid configure $w -padx 5 -pady 5}
	
	focus .c.lf.mfl
	
	::tk::PlaceWindow . widget
	
	bind . <Return> { NZZMESHER }

} else {

	if {[llength $argv] == 2} {
		set MparafullFilename [lindex $argv 0]
		set NprofullFilename [lindex $argv 1]
		set nprofile [file tail $NprofullFilename]
		set MeshParameters [file tail $MparafullFilename]
	} elseif {[llength $argv] == 1} {
		set NprofullFilename [lindex $argv 0]
		set nprofile [file tail $NprofullFilename]
	} else {
		puts "Invalid command line input! WITHOUT NOZZLE PROFILE AS INPUT THIS SCRIPT DOESN'T WORK."
		puts "Usage: pointwise -b NZZmesher.glf ?MeshParameters.glf? nozzle_profile.txt <Profile File>"
		exit
	}

	NZZMESHER
}
