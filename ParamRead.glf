# =============================================================
# This script is written to generate structured multi-block
# grid for a nozzle profile with respect to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc ParamDefualt {fdef} {

	set fdefinterp [interp create -safe]

	set fp [open $fdef r]
	set defscript [read $fp]
	close $fp

	$fdefinterp eval $defscript

	global res_lev GRD_TYP NZZ_BLTK NZZ_ROT_STEP Sponge_iGR Sponge_oGR FWH_slp FWH_GR \
		FWH_GRP FWH_R unmarked_export FWH_winterface_export cae_solver save_native \
		TARG_YPR TARG_GR St Nw UUP defParas meshparacol

	set defParas [list res_lev GRD_TYP NZZ_BLTK NZZ_ROT_STEP Sponge_iGR Sponge_oGR FWH_slp FWH_GR \
		FWH_GRP FWH_R unmarked_export FWH_winterface_export cae_solver save_native \
		TARG_YPR TARG_GR St Nw UUP]

	foreach para $defParas {
		set parav [$fdefinterp eval "set ${para}"]
			set ${para} $parav
			lappend meshparacol [list $parav]
	}
	
	return 0
}
