# =============================================================
# This script is written to generate structured multi-block
# grid for a nozzle profile with respect to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc CAE_Export {blk} {

	global scriptDir save_native res_lev fexmod unmarked_export
	global FWH_winterface_export save_native scriptDir
	global gridname gridnameFWHint gridnameFWHmrk
	global nozz_upfront_con FWH_R D_blkright D_blkleft
	
	upvar 1 cae_solver cae_fmt
	upvar 1 symsepdd asep

	#=============================================CAE EXPORT=============================================

	# creating general boundary conditions
	set bcnozz [pw::BoundaryCondition create]
		$bcnozz setName nozzle
	set bcfarfield [pw::BoundaryCondition create]
		$bcfarfield setName farfield
	set bcinlet [pw::BoundaryCondition create]
		$bcinlet setName inlet

	#assigning BCs
	#CAE Boundary Condition
	set domNOZZqbc []
	set blkNOZZqbc []
	set domFARFIELDqbc []
	set blkFARFIELDqbc []
	set domINLETqbc []
	set blkINLETqbc []

	array set dommNOZZqbc []
	array set dommFARFIELDqbc []
	array set dommINLETqbc []

	for {set k 1} {$k<=[llength $blk]} {incr k} {
		set dommNOZZqbc($k) []
		set dommFARFIELDqbc($k) []
		set dommINLETqbc($k) []
	}

	# finding proper domains and blocks corresponding to BCs
	#block 0
	set dommNOZZqbc(1) [[[lindex $blk 0] getFace 3] getDomains]
	set dommINLETqbc(1) [[[lindex $blk 0] getFace 4] getDomains]

	foreach ent $dommNOZZqbc(1) {
		lappend domNOZZqbc $ent
		lappend blkNOZZqbc [lindex $blk 0]
	}

	foreach ent $dommINLETqbc(1) {
		lappend domINLETqbc $ent
		lappend blkINLETqbc [lindex $blk 0]
	}

	#block 1
	set dommNOZZqbc(2) [[[lindex $blk 1] getFace 3] getDomains]
	set dommINLETqbc(2) [[[lindex $blk 1] getFace 4] getDomains]

	foreach ent $dommNOZZqbc(2) {
		lappend domNOZZqbc $ent
		lappend blkNOZZqbc [lindex $blk 1]
	}

	foreach ent $dommINLETqbc(2) {
		lappend domINLETqbc $ent
		lappend blkINLETqbc [lindex $blk 1]
	}

	#block 2
	set dommINLETqbc(3) [[[lindex $blk 2] getFace 2] getDomains]

	foreach ent $dommINLETqbc(3) {
		lappend domINLETqbc $ent
		lappend blkINLETqbc [lindex $blk 2]
	}

	#block 3
	set dommFARFIELDqbc(1) [[[lindex $blk 3] getFace 5] getDomains]

	foreach ent $dommFARFIELDqbc(1) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 3]
	}

	#block 3
	set dommFARFIELDqbc(2) [[[lindex $blk 3] getFace 2] getDomains]

	foreach ent $dommFARFIELDqbc(2) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 3]
	}

	#block 3
	set dommNOZZqbc(3) [[[lindex $blk 3] getFace 3] getDomains]

	foreach ent $dommNOZZqbc(3) {
		lappend domNOZZqbc $ent
		lappend blkNOZZqbc [lindex $blk 3]
	}

	#block 4
	set dommFARFIELDqbc(3) [[[lindex $blk 4] getFace 5] getDomains]

	foreach ent $dommFARFIELDqbc(3) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 4]
	}

	#block 4
	set dommFARFIELDqbc(3) [[[lindex $blk 4] getFace 2] getDomains]

	foreach ent $dommFARFIELDqbc(3) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 4]
	}

	#block 4
	set dommNOZZqbc(4) [[[lindex $blk 4] getFace 3] getDomains]

	foreach ent $dommNOZZqbc(4) {
		lappend domNOZZqbc $ent
		lappend blkNOZZqbc [lindex $blk 4]
	}

	#block 9
	set dommFARFIELDqbc(3) [[[lindex $blk 9] getFace 4] getDomains]
	set dommNOZZqbc(5) [[[lindex $blk 9] getFace 6] getDomains]

	foreach ent $dommFARFIELDqbc(3) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 9]
	}

	lappend domNOZZqbc [lindex $dommNOZZqbc(5) 1]
	lappend blkNOZZqbc [lindex $blk 9]

	#block 10
	set dommFARFIELDqbc(4) [[[lindex $blk 10] getFace 4] getDomains]
	set dommNOZZqbc(6) [[[lindex $blk 10] getFace 6] getDomains]

	foreach ent $dommFARFIELDqbc(4) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 10]
	}

	lappend domNOZZqbc [lindex $dommNOZZqbc(6) 1]
	lappend blkNOZZqbc [lindex $blk 10]

	#block 11
	set dommFARFIELDqbc(5) [[[lindex $blk 11] getFace 6] getDomains]

	foreach ent $dommFARFIELDqbc(5) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 11]
	}

	#block 12
	set dommFARFIELDqbc(6) [[[lindex $blk 12] getFace 6] getDomains]

	foreach ent $dommFARFIELDqbc(6) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 12]
	}

	#block 13
	set dommFARFIELDqbc(7) [[[lindex $blk 13] getFace 3] getDomains]

	foreach ent $dommFARFIELDqbc(7) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 13]
	}

	#block 14
	set dommFARFIELDqbc(8) [[[lindex $blk 13] getFace 2] getDomains]

	foreach ent $dommFARFIELDqbc(8) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 13]
	}

	#block 15
	set dommFARFIELDqbc(9) [[[lindex $blk 14] getFace 3] getDomains]

	foreach ent $dommFARFIELDqbc(9) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 14]
	}

	#block 16
	set dommFARFIELDqbc(10) [[[lindex $blk 14] getFace 2] getDomains]

	foreach ent $dommFARFIELDqbc(10) {
		lappend domFARFIELDqbc $ent
		lappend blkFARFIELDqbc [lindex $blk 14]
	}

	#assigning domains to BCs
	foreach domain $domNOZZqbc block $blkNOZZqbc {
		$bcnozz apply [list [list $block $domain]]
	}

	foreach domain $domINLETqbc block $blkINLETqbc {
		$bcinlet apply [list [list $block $domain]]
	}

	foreach domain $domFARFIELDqbc block $blkFARFIELDqbc {
		$bcfarfield apply [list [list $block $domain]]
	}

	#examine
	set blkexm [pw::Examine create BlockVolume]
	$blkexm addEntity $blk
	$blkexm examine
	set blkexmv [$blkexm getMinimum]
	
	set dashes [string repeat - 70]
	
	foreach bl $blk {
		lappend blkncells [$bl getCellCount]
	}

	set blkncell [expr [join $blkncells +]]
	set blkorder [string length $blkncell]

	if {$blkorder<7} {
		set blkID "[string range $blkncell 0 2]k"
	} elseif {$blkorder>=7 && $blkorder<10} {
		set blkID "[string range [expr $blkncell/1000000] 0 2]m[string range [expr int($blkncell%1000000)] 0 2]k"
	} elseif {$blkorder>=10 && $blkorder<13} {
		set blkID "[string range [expr $blkncell/1000000000] 0 2]b[string range [expr int($blkncell%1000000000)] 0 2]m"
	}

	append gridname lev $res_lev "_" $blkID

	append gridnameFWHint lev $res_lev "_" $blkID "_FWHinterface" 

	append gridnameFWHmrk lev $res_lev "_" $blkID "_FWHmarked" 

	puts $fexmod [string repeat - 50]
	puts $fexmod "3D MULTIBLOCK STRUCTURED GRID | NOZZLE CONFIG | GRID LEVEL $res_lev:"
	puts $fexmod [string repeat - 50]
	puts $fexmod "total blocks: [llength $blkncells]"
	puts $fexmod "total cells: $blkncell cells"
	puts $fexmod "min volume: [format "%*e" 5 $blkexmv]"

	if {[string compare $unmarked_export YES]==0} {
			# creating export directory
			set exportDir [file join $scriptDir grids]

			file mkdir $exportDir
			
			puts $fexmod [string repeat - 50]
			# CAE specificity in the output file!
			puts $fexmod "Current solver: [set curSolver [pw::Application getCAESolver]]"

			set validExts [pw::Application getCAESolverAttribute FileExtensions]
			puts $fexmod "Valid file extensions: '$validExts'"

			set defExt [lindex $validExts 0]

			set caex [pw::Application begin CaeExport $blk]

			set destType [pw::Application getCAESolverAttribute FileDestination]
			switch $destType {
				Filename { set dest [file join $exportDir "$gridname.$defExt"] }
				Folder   { set dest $exportDir }
				default  { return -code error "Unexpected FileDestination value" }
			}
			puts $fexmod "Exporting to $destType: '$dest'"
			puts $fexmod [string repeat - 50]

			# Initialize the CaeExport mode
			set status abort  ;
			if { ![$caex initialize $dest] } {
				puts $fexmod {$caex initialize failed!}
			} else {
				if { ![catch {$caex setAttribute FilePrecision Double}] } {
					puts $fexmod "setAttribute FilePrecision Double"
				}

				if { ![$caex verify] } {
					puts $fexmod {$caex verify failed!}
				} elseif { ![$caex canWrite] } {
					puts $fexmod {$caex canWrite failed!}
				} elseif { ![$caex write] } {
					puts $fexmod {$caex write failed!}
				} elseif { 0 != [llength [set feCnts [$caex getForeignEntityCounts]]] } {
				# print entity counts reported by the exporter
				set fmt {   %-22.22s | %6.6s |}
				puts $fexmod "Number of grid entities exported:"
				puts $fexmod [format $fmt {Entity Type} Count]
				puts $fexmod [format $fmt $dashes $dashes]
				dict for {key val} $feCnts {
					puts $fexmod [format $fmt $key $val]
				}
				set status end ;# all is okay now
				}
			}

			# Display any errors/warnings
			set errCnt [$caex getErrorCount]
			for {set ndx 1} {$ndx <= $errCnt} {incr ndx} {
				puts $fexmod "[$caex getErrorCode $ndx]: '[$caex getErrorInformation $ndx]'"
			}
			# abort/end the CaeExport mode
			$caex $status

	puts $dashes
	puts "GRID WITHOUT FWH MARKER/INTERFACE EXPORTED FOR LEVEL $res_lev."
	puts "info: grid information can be found in CAE_export.out"

	}

	if {[string compare $save_native YES]==0} {
		set exportDir [file join $scriptDir grids]
		file mkdir $exportDir
		pw::Application save "$exportDir/$gridname.pw"
	}

	if {[string compare $FWH_winterface_export YES]==0} {
		
		set nozz_upfront_con_sp [$nozz_upfront_con split -I \
			[list [lindex [$nozz_upfront_con closestCoordinate \
						[$nozz_upfront_con getPosition -Y $FWH_R]] 0]]]

		set D_blkright_sp [$D_blkright split -K \
					[expr [[lindex $nozz_upfront_con_sp 0] getDimension]+1]]
		set D_blkleft_sp [$D_blkleft split -K \
					[expr [[lindex $nozz_upfront_con_sp 0] getDimension]+1]]

		set bcinterface [pw::BoundaryCondition create]
			$bcinterface setName FWHinterface
		
		set domFWHqbc []
		set blkFWHqbc []

		array set dommFWHqbc []

		for {set k 1} {$k<=[llength $blk]} {incr k} {
			set dommFWHqbc($k) []
		}

		# finding proper domains and blocks corresponding to BCs
		#block 0
		set dommFWHqbc(1) [[[lindex $D_blkright_sp 0] getFace 4] getDomains]

		lappend domFWHqbc [lindex $dommFWHqbc(1) 0]
		lappend blkFWHqbc [lindex $D_blkright_sp 0]
		
		set dommFWHqbc(2) [[[lindex $D_blkleft_sp 0] getFace 4] getDomains]

		lappend domFWHqbc [lindex $dommFWHqbc(2) 0]
		lappend blkFWHqbc [lindex $D_blkleft_sp 0]

		#assigning domains to BCs
		foreach domain $domFWHqbc block $blkFWHqbc {
			$bcinterface apply [list [list $block $domain]]
		}
		
		set fwhblks [pw::Grid getAll -type pw::Block]
		
		set exportDir [file join $scriptDir grids]

		file mkdir $exportDir
		
		set validExts [pw::Application getCAESolverAttribute FileExtensions]
		puts $fexmod "Valid file extensions: '$validExts'"

		set defExt [lindex $validExts 0]
		
		set destType [pw::Application getCAESolverAttribute FileDestination]
		switch $destType {
			Filename { set dest [file join $exportDir "$gridnameFWHint.$defExt"] }
			Folder   { set dest $exportDir }
			default  { return -code error "Unexpected FileDestination value" }
		}
		
		set caexint [pw::Application begin CaeExport $fwhblks]
		
		$caexint initialize $dest
		$caexint setAttribute FilePrecision Double
		$caexint verify
		$caexint write
		$caexint end
		
		if {[string compare $save_native YES]==0} {
			set exportDir [file join $scriptDir grids]
			file mkdir $exportDir
			pw::Application save "$exportDir/$gridnameFWHint.pw"
		}

	puts $dashes
	puts "GRID WITH FWH INTERFACE EXPORTED FOR LEVEL $res_lev."
	puts "info: to append the FWH surface as a marker to the grid without FWH marker/interface you need to run:"
	puts "tclsh FWHMarker.tcl"
	puts "FWHMarker.tcl requires both: grids with and without FWH interface in SU2 formats!"

	}

}
