# =============================================================
# This script is written to generate structured multi-block
# grid for a nozzle profile with respect to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc GridFlowprop_Update {plablist meshvlist guidedir} {
	
	set k 20
		
	foreach label $plablist param $meshvlist {
		exec sed -i "0,/$label/{/$label/d;}" $guidedir/gridflowprop.py
		exec sed -i "$k a $label = \[$param\]" $guidedir/gridflowprop.py
		incr k 4
	} 
	
	exec python3 $guidedir/gridflowprop.py
	return 0
}
