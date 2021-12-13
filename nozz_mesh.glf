# =============================================================
# This script is written to generate structured multi-block
# grid for a nozzle profile with respect to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

proc Nozzle_Mesh {} {
	
	global nx_node ny_node nozzUpperCurve nozzLowerCurve nozzTeCurve nozzLowerCurve_sp
	global NZZ_BLTK NZZ_ROT_STEP Sponge_iGR Sponge_oGR FWH_slp FWH_GR FWH_GRP res_lev
	global nozz_upfront_con FWH_R D_blkright D_blkleft cae_solver
	global domBCs blkBCs
	
	upvar 1 grg NZZ_IN_GR
	upvar 1 dsg NZZ_DS
	upvar 1 chord_sg NZZ_IN_SPC
	upvar 1 GRD_TYP grid_type
	
	# collecting boundaries as it builds
	array set domBCs []
	array set blkBCs []
	
	#--------------------------------------------------

	# Create FarField
	set nozzFar [pw::Application begin Create]
	set nozzFarPts [pw::SegmentSpline create]
	$nozzFarPts setSlope Free

	$nozzFarPts addPoint [list 0 20 0]
	$nozzFarPts addPoint [list 50 40 0]

	$nozzFarPts setSlopeOut 1 {33.948334619740201 -0.021626272409800862 0}
	$nozzFarPts setSlopeIn 2 {-30.2782087944274 0.45412873257959774 0}

	set nozzFarCurve [pw::Curve create]

	$nozzFarCurve addSegment $nozzFarPts
	$nozzFar end

	# --------------------------------------------------
	
	pw::Application setCAESolver $cae_solver 3
	
	#--------------------------------------------------

	set nzz_inn_con [pw::Connector createOnDatabase -parametricConnectors Aligned [list $nozzLowerCurve]]

	#--------------------------------------------------

	$nzz_inn_con setDimensionFromSpacing $NZZ_IN_SPC

	set nzz_inn_edg [pw::Edge createFromConnectors [list $nzz_inn_con]]

	set nzz_inn_BLdom [pw::DomainStructured create]

	$nzz_inn_BLdom addEdge $nzz_inn_edg

	set nzz_inn_extr [pw::Application begin ExtrusionSolver [list $nzz_inn_BLdom]]

	$nzz_inn_BLdom setExtrusionBoundaryCondition Begin ConstantX
	$nzz_inn_BLdom setExtrusionBoundaryCondition End ConstantX

	$nzz_inn_BLdom setExtrusionSolverAttribute SpacingGrowthFactor $NZZ_IN_GR
	$nzz_inn_BLdom setExtrusionSolverAttribute NormalInitialStepSize $NZZ_DS
	$nzz_inn_BLdom setExtrusionSolverAttribute StopAtHeight $NZZ_BLTK

	$nzz_inn_extr run 75
	$nzz_inn_extr end

	#-------------------------------------------------

	set nzz_inn_surf [pw::Surface create]
	$nzz_inn_surf revolve -angle 360 $nozzLowerCurve {0 0 0} {1 0 0}

	set nzz_BLface [pw::FaceStructured createFromDomains [list $nzz_inn_BLdom]]
	set nzz_BLblk [pw::BlockStructured create]
	$nzz_BLblk addFace $nzz_BLface

	set nzz_BLblk_extr [pw::Application begin ExtrusionSolver [list $nzz_BLblk]]
	$nzz_BLblk setExtrusionSolverAttribute Mode Rotate
	$nzz_BLblk setExtrusionSolverAttribute RotateAxisStart {0 0 0}
	$nzz_BLblk setExtrusionSolverAttribute RotateAxisEnd [pwu::Vector3 add {0 0 0} {1 0 0}]
	$nzz_BLblk setExtrusionSolverAttribute RotateAngle 360
	$nzz_BLblk_extr run $NZZ_ROT_STEP
	$nzz_BLblk_extr end

	set nzz_BLblk_sp [$nzz_BLblk split -K [list [expr ($NZZ_ROT_STEP/2)+1]]]

	set nzz_BLblk_rcon1 [[[[lindex $nzz_BLblk_sp 0] getFace 4] getEdge 2] getConnector 1]
	set nzz_BLblk_rcon2 [[[[lindex $nzz_BLblk_sp 0] getFace 2] getEdge 4] getConnector 1]

	set nzz_BLblk_lcon1 [[[[lindex $nzz_BLblk_sp 1] getFace 4] getEdge 2] getConnector 1]
	set nzz_BLblk_lcon2 [[[[lindex $nzz_BLblk_sp 1] getFace 2] getEdge 4] getConnector 1]

	#collecting BC | Nozzle
	lappend domBCs(0) [[[lindex $nzz_BLblk_sp 0] getFace 3] getDomain 1]
	lappend blkBCs(0) [lindex $nzz_BLblk_sp 0]
	lappend domBCs(0) [[[lindex $nzz_BLblk_sp 1] getFace 3] getDomain 1]
	lappend blkBCs(0) [lindex $nzz_BLblk_sp 1]

	#collecting BC | Inlet
	lappend domBCs(1) [[[lindex $nzz_BLblk_sp 0] getFace 4] getDomain 1]
	lappend blkBCs(1) [lindex $nzz_BLblk_sp 0]
	lappend domBCs(1) [[[lindex $nzz_BLblk_sp 1] getFace 4] getDomain 1]
        lappend blkBCs(1) [lindex $nzz_BLblk_sp 1]

	# DOM AT INLET
	#-------------------------------------------------------------------------------------
	set spmiddim1 [expr int(floor([$nzz_BLblk_rcon1 getDimension]/4))+3]

	set nzz_BLblk_rcon1_sp1 [$nzz_BLblk_rcon1 split -I [list $spmiddim1]]

	set spmiddim2 [expr [[lindex $nzz_BLblk_rcon1_sp1 1] getDimension] - $spmiddim1 + 1]

	set nzz_BLblk_rcon1_sp2 [[lindex $nzz_BLblk_rcon1_sp1 1] split -I [list $spmiddim2]]

	set nzz_BLblk_lcon1_sp [$nzz_BLblk_lcon1 split -I [list $spmiddim1 [expr $spmiddim1 + $spmiddim2 -1]]]

	set nzz_in_dom_edg1 [pw::Edge create]
	$nzz_in_dom_edg1 addConnector [lindex $nzz_BLblk_rcon1_sp1 0]
	$nzz_in_dom_edg1 addConnector [lindex $nzz_BLblk_lcon1_sp 2]

	set nzz_in_dom_edg2 [pw::Edge create]
	$nzz_in_dom_edg2 addConnector [lindex $nzz_BLblk_lcon1_sp 1]

	set nzz_in_dom_edg3 [pw::Edge create]
	$nzz_in_dom_edg3 addConnector [lindex $nzz_BLblk_lcon1_sp 0]
	$nzz_in_dom_edg3 addConnector [lindex $nzz_BLblk_rcon1_sp2 1]

	set nzz_in_dom_edg4 [pw::Edge create]
	$nzz_in_dom_edg4 addConnector [lindex $nzz_BLblk_rcon1_sp2 0]

	set nzz_in_dom [pw::DomainStructured create]
	$nzz_in_dom addEdge $nzz_in_dom_edg1
	$nzz_in_dom addEdge $nzz_in_dom_edg2
	$nzz_in_dom addEdge $nzz_in_dom_edg3
	$nzz_in_dom addEdge $nzz_in_dom_edg4

	set nzz_in_dom_slv [pw::Application begin EllipticSolver [list $nzz_in_dom]]
	$nzz_in_dom_slv run $NZZ_ROT_STEP
	$nzz_in_dom_slv end

	# DOM AT OUTLET
	#-------------------------------------------------------------------------------------

	set nzz_BLblk_rcon2_sp [$nzz_BLblk_rcon2 split -I [list $spmiddim1 [expr $spmiddim1 + $spmiddim2 -1]]]

	set nzz_BLblk_lcon2_sp [$nzz_BLblk_lcon2 split -I [list $spmiddim1 [expr $spmiddim1 + $spmiddim2 -1]]]

	set nzz_out_dom_edg1 [pw::Edge create]
	$nzz_out_dom_edg1 addConnector [lindex $nzz_BLblk_rcon2_sp 0]
	$nzz_out_dom_edg1 addConnector [lindex $nzz_BLblk_lcon2_sp 2]

	set nzz_out_dom_edg2 [pw::Edge create]
	$nzz_out_dom_edg2 addConnector [lindex $nzz_BLblk_lcon2_sp 1]

	set nzz_out_dom_edg3 [pw::Edge create]
	$nzz_out_dom_edg3 addConnector [lindex $nzz_BLblk_lcon2_sp 0]
	$nzz_out_dom_edg3 addConnector [lindex $nzz_BLblk_rcon2_sp 2]

	set nzz_out_dom_edg4 [pw::Edge create]
	$nzz_out_dom_edg4 addConnector [lindex $nzz_BLblk_rcon2_sp 1]

	set nzz_out_dom [pw::DomainStructured create]
	$nzz_out_dom addEdge $nzz_out_dom_edg1
	$nzz_out_dom addEdge $nzz_out_dom_edg2
	$nzz_out_dom addEdge $nzz_out_dom_edg3
	$nzz_out_dom addEdge $nzz_out_dom_edg4

	set nzz_out_dom_slv [pw::Application begin EllipticSolver [list $nzz_out_dom]]
	$nzz_out_dom_slv run $NZZ_ROT_STEP
	$nzz_out_dom_slv end

	# NOZZLE BLOCK
	# -----------------------------------------------------------------------------------

	set inn_nzz_domr [[[lindex $nzz_BLblk_sp 0] getFace 5] getDomain 1]
	set inn_nzz_doml [[[lindex $nzz_BLblk_sp 1] getFace 5] getDomain 1]

	set inn_nzz_domrf [[[lindex $nzz_BLblk_sp 0] getFace 2] getDomain 1]
	set inn_nzz_domlf [[[lindex $nzz_BLblk_sp 1] getFace 2] getDomain 1]

	set inn_nzz_tck1 [[[[lindex $nzz_BLblk_sp 1] getFace 6] getEdge 4] getConnector 1]
	set inn_nzz_tck2 [[[[lindex $nzz_BLblk_sp 1] getFace 1] getEdge 4] getConnector 1]

	set nzz_BLtck [$inn_nzz_tck1 getDimension]

	set inn_nzz_domr_sp [$inn_nzz_domr split -J [list $spmiddim1 [expr $spmiddim1 + $spmiddim2 -1]]]
	set inn_nzz_doml_sp [$inn_nzz_doml split -J [list $spmiddim1 [expr $spmiddim1 + $spmiddim2 -1]]]

	set inn_nzz_blk [pw::BlockStructured createFromDomains [list [lindex $inn_nzz_domr_sp 0]\
									[lindex $inn_nzz_domr_sp 1]\
									[lindex $inn_nzz_domr_sp 2]\
									[lindex $inn_nzz_doml_sp 0]\
									[lindex $inn_nzz_doml_sp 1]\
									[lindex $inn_nzz_doml_sp 2]\
									$nzz_in_dom $nzz_out_dom]]
	
	#collecting BC | Nozzle
	lappend domBCs(0) [[$inn_nzz_blk getFace 2] getDomain 1]
	lappend blkBCs(0) $inn_nzz_blk
	lappend domBCs(0) [[$inn_nzz_blk getFace 4] getDomain 1]
	lappend blkBCs(0) $inn_nzz_blk
	lappend domBCs(0) [[$inn_nzz_blk getFace 5] getDomain 1]
	lappend blkBCs(0) $inn_nzz_blk
	lappend domBCs(0) [[$inn_nzz_blk getFace 6] getDomain 1]
	lappend blkBCs(0) $inn_nzz_blk
	
	#collecting BC | inlet
	lappend domBCs(1) [[$inn_nzz_blk getFace 3] getDomain 1]
	lappend blkBCs(1) $inn_nzz_blk

	# ----------------------------------------- NOZZLE UP ---------------------------------

	# examine edge length
	set nzz_bl_front_con [[[[lindex $nzz_BLblk_sp 0] getFace 1] getEdge 4] getConnector 1]

	set front_edg_exm [pw::Examine create ConnectorEdgeLength]
	$front_edg_exm addEntity $nzz_bl_front_con
	$front_edg_exm examine
	set front_edg_value [$front_edg_exm getValue $nzz_bl_front_con 1]

	set nzz_outt_surf [pw::Surface create]
	$nzz_outt_surf revolve -angle 360 $nozzUpperCurve {0 0 0} {1 0 0}

	set nzz_outt_con [pw::Connector createOnDatabase -parametricConnectors Aligned [list $nozzUpperCurve]]

	set nzz_far_con [pw::Connector createOnDatabase -parametricConnectors Aligned [list $nozzFarCurve]]

	# front connector
	set nozzUpFront_seg [pw::SegmentSpline create]
	$nozzUpFront_seg setSlope Free

	$nozzUpFront_seg addPoint [[$nzz_outt_con getNode End] getXYZ]
	$nozzUpFront_seg addPoint [[$nzz_far_con getNode Begin] getXYZ]

	set nozz_upfront_con [pw::Connector create]

	$nozz_upfront_con addSegment $nozzUpFront_seg

	# top connector
	set nozzUpTop_seg [pw::SegmentSpline create]
	$nozzUpTop_seg setSlope Free

	$nozzUpTop_seg addPoint [list [lindex $nx_node 0] 20 0]
	$nozzUpTop_seg addPoint [[$nzz_far_con getNode Begin] getXYZ]

	set nozz_uptop_con [pw::Connector create]

	$nozz_uptop_con addSegment $nozzUpTop_seg

	# back connector
	set nozzUpBck_seg [pw::SegmentSpline create]
	$nozzUpBck_seg setSlope Free

	$nozzUpBck_seg addPoint [list [lindex $nx_node 0] 20 0]
	$nozzUpBck_seg addPoint [[$nzz_outt_con getNode Begin] getXYZ]

	set nozz_upback_con [pw::Connector create]

	$nozz_upback_con addSegment $nozzUpBck_seg

	# Dimension
	$nzz_outt_con setDimension [expr int([$nzz_inn_con getDimension]/5)]
	$nozz_uptop_con setDimension [$nzz_outt_con getDimension]

	$nozz_upback_con setDimensionFromSpacing [$nzz_outt_con getAverageSpacing]

	[$nozz_upback_con getDistribution 1] setEndSpacing $front_edg_value

	$nozz_upback_con addBreakPoint -Y 6

	pw::Connector swapDistribution Growth [list [list $nozz_upback_con 2]]
	[$nozz_upback_con getDistribution 2] setEndMode HeightAndRate
	[$nozz_upback_con getDistribution 2] setEndHeight 6
	[$nozz_upback_con getDistribution 2] setEndRate $Sponge_iGR
	$nozz_upback_con setSubConnectorDimensionFromDistribution 2

	#examine
	set nozzupbackdisexm [pw::Examine create ConnectorEdgeLength]
	$nozzupbackdisexm addEntity $nozz_upback_con
	$nozzupbackdisexm examine
	set nozzupbackdisexm_value [$nozzupbackdisexm getValue $nozz_upback_con \
							[expr [$nozz_upback_con getSubConnectorDimension 1]]]

	[$nozz_upback_con getDistribution 1] setEndSpacing $nozzupbackdisexm_value

	pw::Connector swapDistribution Growth [list [list $nozz_upback_con 1]]
	[$nozz_upback_con getDistribution 1] setEndMode HeightAndRate
	[$nozz_upback_con getDistribution 1] setEndHeight 15
	[$nozz_upback_con getDistribution 1] setEndRate $Sponge_oGR
	$nozz_upback_con setSubConnectorDimensionFromDistribution 1

	[$nozz_upfront_con getDistribution 1] setBeginSpacing $front_edg_value
	$nozz_upfront_con setDimension [$nozz_upback_con getDimension]

	set nozzupfrontdis [pw::DistributionGeneral create \
						[list [list $nozz_upback_con 1] [list $nozz_upback_con 2]]]

	$nozzupfrontdis setBeginSpacing 0
	$nozzupfrontdis setEndSpacing 0
	$nozzupfrontdis setVariable [[$nozz_upfront_con getDistribution 1] getVariable]
	$nozz_upfront_con setDistribution 1 $nozzupfrontdis
	[$nozz_upfront_con getDistribution 1] reverse

	set nzz_outt_dom [pw::DomainStructured createFromConnectors [list $nzz_outt_con\
								$nozz_uptop_con\
								$nozz_upfront_con\
								$nozz_upback_con]]

	#revolve
	set nzz_outface [pw::FaceStructured createFromDomains [list $nzz_outt_dom]]
	set nzz_outblk [pw::BlockStructured create]
	$nzz_outblk addFace $nzz_outface

	set nzz_outblk_extr [pw::Application begin ExtrusionSolver [list $nzz_outblk]]
	$nzz_outblk setExtrusionSolverAttribute Mode Rotate
	$nzz_outblk setExtrusionSolverAttribute RotateAxisStart {0 0 0}
	$nzz_outblk setExtrusionSolverAttribute RotateAxisEnd [pwu::Vector3 add {0 0 0} {1 0 0}]
	$nzz_outblk setExtrusionSolverAttribute RotateAngle 360
	$nzz_outblk_extr run $NZZ_ROT_STEP
	$nzz_outblk_extr end

	pw::Entity project -type ClosestPoint -interior [[$nzz_outblk getFace 3] getDomain 1]

	set nzz_outblk_sp [$nzz_outblk split -K [expr ($NZZ_ROT_STEP/2)+1]]

	set nzz_outblk_rcon [[[[lindex $nzz_outblk_sp 0] getFace 4] getEdge 4] getConnector 1]
	set nzz_outblk_lcon [[[[lindex $nzz_outblk_sp 1] getFace 4] getEdge 4] getConnector 1]

	set nzz_outblk_rbcon [[[[lindex $nzz_outblk_sp 0] getFace 4] getEdge 3] getConnector 1]

	set nzz_innblk_rcon [[[[lindex $nzz_BLblk_sp 0] getFace 2] getEdge 2] getConnector 1]
	set nzz_innblk_lcon [[[[lindex $nzz_BLblk_sp 1] getFace 2] getEdge 2] getConnector 1]


	#collecting BC | Nozzle
	lappend domBCs(0) [[[lindex $nzz_outblk_sp 0] getFace 3] getDomain 1]
	lappend blkBCs(0) [lindex $nzz_outblk_sp 0]
	
	#collecting BC | far1
	lappend domBCs(2) [[[lindex $nzz_outblk_sp 0] getFace 2] getDomain 1]
	lappend blkBCs(2) [lindex $nzz_outblk_sp 0]

	#collecting BC | far2
	lappend domBCs(3) [[[lindex $nzz_outblk_sp 0] getFace 5] getDomain 1]
	lappend blkBCs(3) [lindex $nzz_outblk_sp 0]


	#collecting BC | Nozzle
	lappend domBCs(0) [[[lindex $nzz_outblk_sp 1] getFace 3] getDomain 1]
	lappend blkBCs(0) [lindex $nzz_outblk_sp 1]
	
	#collecting BC | far1
	lappend domBCs(2) [[[lindex $nzz_outblk_sp 1] getFace 2] getDomain 1]
	lappend blkBCs(2) [lindex $nzz_outblk_sp 1]

	#collecting BC | far2
	lappend domBCs(3) [[[lindex $nzz_outblk_sp 1] getFace 5] getDomain 1]
	lappend blkBCs(3) [lindex $nzz_outblk_sp 1]

	# edge connector top
	set edgtop_seg [pw::SegmentSpline create]
	$edgtop_seg setSlope Free

	$edgtop_seg addPoint [[$nzz_outblk_rcon getNode Begin] getXYZ]
	$edgtop_seg addPoint [[$nzz_innblk_rcon getNode Begin] getXYZ]

	set edgtop_con [pw::Connector create]

	$edgtop_con addSegment $edgtop_seg

	$edgtop_con setDimensionFromSpacing $front_edg_value

	# edge connector bottom
	set edgbot_seg [pw::SegmentSpline create]
	$edgbot_seg setSlope Free

	$edgbot_seg addPoint [[$nzz_outblk_rcon getNode End] getXYZ]
	$edgbot_seg addPoint [[$nzz_innblk_rcon getNode End] getXYZ]

	set edgbot_con [pw::Connector create]

	$edgbot_con addSegment $edgbot_seg

	$edgbot_con setDimension [$edgtop_con getDimension]

	set nzz_tck_top [pw::DomainStructured createFromConnectors [list $edgbot_con\
								$edgtop_con\
								$nzz_outblk_rcon\
								$nzz_innblk_rcon]]
								
	set nzz_tck_bot [pw::DomainStructured createFromConnectors [list $edgbot_con\
								$edgtop_con\
								$nzz_outblk_lcon\
								$nzz_innblk_lcon]]

	set D_R [expr 0.5+$FWH_slp*30]

	#30D STATION
	set D_seg [pw::SegmentCircle create]
	$D_seg addPoint [list 30 $D_R 0]
	$D_seg addPoint {30 0 0}
	$D_seg setEndAngle 360 {1 0 0}
	set D_con [pw::Connector create]
	$D_con addSegment $D_seg

	$D_con setDimension [expr $NZZ_ROT_STEP+1]

	set D_con_sp [$D_con split [$D_con getParameter -arc 0.5]]

	set D_inn_edg [pw::Edge createFromConnectors [list [lindex $D_con_sp 0] [lindex $D_con_sp 1]]]

	set D_inn_BLdom [pw::DomainStructured create]

	$D_inn_BLdom addEdge $D_inn_edg

	set D_inn_extr [pw::Application begin ExtrusionSolver [list $D_inn_BLdom]]

	$D_inn_BLdom setExtrusionSolverAttribute NormalMarchingMode Plane
	$D_inn_BLdom setExtrusionSolverAttribute NormalMarchingVector {1 -0 -0}
	$D_inn_BLdom setExtrusionSolverAttribute SpacingGrowthFactor $NZZ_IN_GR
	$D_inn_BLdom setExtrusionSolverAttribute NormalInitialStepSize $NZZ_DS

	$D_inn_extr run [expr $nzz_BLtck-1]
	$D_inn_extr end

	set D_inncon [[$D_inn_BLdom getEdge 3] getConnector 1]

	set D_inncon_sp [$D_inncon split -I [expr int($NZZ_ROT_STEP/2)+1]]

	set D_inncon_spspr [[lindex $D_inncon_sp 0] split -I [list $spmiddim1 [expr $spmiddim1 + $spmiddim2 -1]]]
	set D_inncon_spspl [[lindex $D_inncon_sp 1] split -I [list $spmiddim1 [expr $spmiddim1 + $spmiddim2 -1]]]

	set D_inn_BLdom_sp [$D_inn_BLdom split -I [expr int($NZZ_ROT_STEP/2)+1]]
	set D_tck1 [[[lindex $D_inn_BLdom_sp 0] getEdge 2] getConnector 1]
	set D_tck2 [[[lindex $D_inn_BLdom_sp 0] getEdge 4] getConnector 1]

	set D_edg1 [pw::Edge create]
	$D_edg1 addConnector [lindex $D_inncon_spspr 2]
	$D_edg1 addConnector [lindex $D_inncon_spspl 0]

	set D_edg2 [pw::Edge create]
	$D_edg2 addConnector [lindex $D_inncon_spspl 1]

	set D_edg3 [pw::Edge create]
	$D_edg3 addConnector [lindex $D_inncon_spspl 2]
	$D_edg3 addConnector [lindex $D_inncon_spspr 0]

	set D_edg4 [pw::Edge create]
	$D_edg4 addConnector [lindex $D_inncon_spspr 1]

	set D_inn_dom [pw::DomainStructured create]
	$D_inn_dom addEdge $D_edg1
	$D_inn_dom addEdge $D_edg2
	$D_inn_dom addEdge $D_edg3
	$D_inn_dom addEdge $D_edg4

	set D_inn_dom_slv [pw::Application begin EllipticSolver [list $D_inn_dom]]
	$D_inn_dom_slv run $NZZ_ROT_STEP
	$D_inn_dom_slv end

	set D_inn_dom_sp [$D_inn_dom split -I [[lindex $D_inncon_spspl 0] getDimension]]
	set nzz_out_dom_sp [$nzz_out_dom split -I [[lindex $D_inncon_spspl 0] getDimension]]
	set nzz_out_dom_midcon [[[lindex $nzz_out_dom_sp 0] getEdge 2] getConnector 1]

	set D_inn_midcon [[[lindex $D_inn_dom_sp 1] getEdge 4] getConnector 1]

	set FWH_curve_seg [pw::SegmentSpline create]
	$FWH_curve_seg addPoint [list [lindex $nx_node 192] [lindex $ny_node 192] 0]
	$FWH_curve_seg addPoint [[[lindex $D_con_sp 0] getNode Begin] getXYZ]
	$FWH_curve_seg setSlope Free
	$FWH_curve_seg setSlopeOut 1 {0.23220261589167601 0.00056916422991104554 0}
	$FWH_curve_seg setSlopeIn 2 {-9.9607251797528988 0.00036843829710797582 0}

	set FWH_curve_con1 [pw::Connector create]
	$FWH_curve_con1 addSegment $FWH_curve_seg

	$FWH_curve_con1 setDimensionFromSpacing [$nzz_outt_con getAverageSpacing]

	[$FWH_curve_con1 getDistribution 1] setBeginSpacing [$nzz_inn_con getAverageSpacing]

	$FWH_curve_con1 addBreakPoint -X 5

	pw::Connector swapDistribution Growth [list [list $FWH_curve_con1 1]]
	[$FWH_curve_con1 getDistribution 1] setBeginMode HeightAndRate
	[$FWH_curve_con1 getDistribution 1] setBeginHeight 5
	[$FWH_curve_con1 getDistribution 1] setBeginRate $FWH_GR
	$FWH_curve_con1 setSubConnectorDimensionFromDistribution 1

	#examine
	set fwhdisexm [pw::Examine create ConnectorEdgeLength]
	$fwhdisexm addEntity $FWH_curve_con1
	$fwhdisexm examine
	set fwhdisexm_value [$fwhdisexm getValue $FWH_curve_con1 \
						[expr [$FWH_curve_con1 getSubConnectorDimension 1]-1]]

	[$FWH_curve_con1 getDistribution 2] setBeginSpacing $fwhdisexm_value

	pw::Connector swapDistribution Growth [list [list $FWH_curve_con1 2]]
	[$FWH_curve_con1 getDistribution 2] setBeginMode HeightAndRate
	[$FWH_curve_con1 getDistribution 2] setBeginHeight 5
	[$FWH_curve_con1 getDistribution 2] setBeginRate [expr ($FWH_GR-1)*($FWH_GRP/100)+$FWH_GR]
	$FWH_curve_con1 setSubConnectorDimensionFromDistribution 2

	set trns_vec [pwu::Vector3 subtract [list [lindex $nx_node 191] [lindex $ny_node 192] 0] \
								[[$inn_nzz_tck1 getNode End] getXYZ]]

	set FWH_curve_con2 \
	[$FWH_curve_con1 createPeriodic -rotate [list 0 0 0] "1 0 0" 180]

	set D_midom [pw::DomainStructured createFromConnectors [list $FWH_curve_con1\
								$inn_nzz_tck1 $nzz_out_dom_midcon $inn_nzz_tck2\
								$FWH_curve_con2 $D_tck1 $D_inn_midcon $D_tck2]]

	set D_midom_sp [$D_midom split -I [list [$D_tck1 getDimension] \
						[expr [$D_inn_midcon getDimension]+[$D_tck1 getDimension]-1]]]

	set D_middom_conu [[[lindex $D_midom_sp 1] getEdge 4] getConnector 1]
	set D_middom_conb [[[lindex $D_midom_sp 1] getEdge 2] getConnector 1]

	set D_sider1 [pw::DomainStructured createFromConnectors [list $FWH_curve_con1 \
									$nzz_innblk_rcon \
									[lindex $D_con_sp 0]\
									$FWH_curve_con2 ]]

	set D_sider2 [pw::DomainStructured createFromConnectors [list $D_middom_conu \
									[lindex $nzz_BLblk_rcon2_sp 0]\
									[lindex $nzz_BLblk_rcon2_sp 1]\
									[lindex $nzz_BLblk_rcon2_sp 2]\
									$D_middom_conb\
									[lindex $D_inncon_spspl 0]\
									[lindex $D_inncon_spspl 1]\
									[lindex $D_inncon_spspl 2]]]

	set D_sider2_sp [$D_sider2 split -I [list $spmiddim1 [expr $spmiddim1 + $spmiddim2 -1]]]

	set D_sidel1 [pw::DomainStructured createFromConnectors [list $FWH_curve_con1 \
									$nzz_innblk_lcon \
									[lindex $D_con_sp 1]\
									$FWH_curve_con2 ]]

	set D_sidel2 [pw::DomainStructured createFromConnectors [list $D_middom_conu \
									[lindex $nzz_BLblk_lcon2_sp 0]\
									[lindex $nzz_BLblk_lcon2_sp 1]\
									[lindex $nzz_BLblk_lcon2_sp 2]\
									$D_middom_conb\
									[lindex $D_inncon_spspr 0]\
									[lindex $D_inncon_spspr 1]\
									[lindex $D_inncon_spspr 2]]]

	set D_sidel2_sp [$D_sidel2 split -I [list $spmiddim1 [expr $spmiddim1 + $spmiddim2 -1]]]

	set D_blk1 [pw::BlockStructured createFromDomains [list [lindex $D_sider2_sp 0] \
								[lindex $D_sider2_sp 1]\
								[lindex $D_sider2_sp 2]\
								[lindex $D_midom_sp 1]\
								[lindex $D_inn_dom_sp 1]\
								[lindex $nzz_out_dom_sp 0]]]

	set D_blk2 [pw::BlockStructured createFromDomains [list $D_sider1 [lindex $D_sider2_sp 0] \
									[lindex $D_sider2_sp 1] \
									[lindex $D_sider2_sp 2] \
									[lindex $D_inn_BLdom_sp 0]\
									[lindex $D_midom_sp 0] \
									[lindex $D_midom_sp 2]\
									$inn_nzz_domrf]]

	set D_blk3 [pw::BlockStructured createFromDomains [list [lindex $D_sidel2_sp 0] \
								[lindex $D_sidel2_sp 1]\
								[lindex $D_sidel2_sp 2]\
								[lindex $D_midom_sp 1]\
								[lindex $D_inn_dom_sp 0]\
								[lindex $nzz_out_dom_sp 1]]]

	set D_blk4 [pw::BlockStructured createFromDomains [list $D_sidel1 [lindex $D_sidel2_sp 0] \
									[lindex $D_sidel2_sp 1] \
									[lindex $D_sidel2_sp 2] \
									[lindex $D_inn_BLdom_sp 1]\
									[lindex $D_midom_sp 0] \
									[lindex $D_midom_sp 2]\
									$inn_nzz_domlf]]


	#outer block
	set nzz_far_con_sp [$nzz_far_con split [$nzz_far_con getParameter -X 30]]

	[lindex $nzz_far_con_sp 0] setDimension [$FWH_curve_con1 getDimension]

	[lindex $nzz_far_con_sp 0] setDistribution 1 [[$FWH_curve_con1 getDistribution 1] copy]

	set D_front_seg [pw::SegmentSpline create]
	$D_front_seg addPoint [[$FWH_curve_con1 getNode End] getXYZ]
	$D_front_seg addPoint [[[lindex $nzz_far_con_sp 0] getNode End] getXYZ]

	set D_frontcon [pw::Connector create]
	$D_frontcon addSegment $D_front_seg

	$D_frontcon setDimension [expr [$nozz_upfront_con getDimension]+[$edgtop_con getDimension]-1]

	$D_frontcon setDistribution 1 [[$nozz_upfront_con getDistribution 1] copy]

	set D_side [pw::DomainStructured createFromConnectors [list $FWH_curve_con1 \
									$D_frontcon \
									[lindex $nzz_far_con_sp 0]\
									$nozz_upfront_con\
									$edgtop_con]]

	#revolve
	set far_edg [pw::Edge createFromConnectors [list [lindex $nzz_far_con_sp 0]]]
	set far_dom [pw::DomainStructured create]
	$far_dom addEdge $far_edg

	set far_extr [pw::Application begin ExtrusionSolver [list $far_dom]]
	$far_dom setExtrusionSolverAttribute Mode Rotate
	$far_dom setExtrusionSolverAttribute RotateAxisStart {0 0 0}
	$far_dom setExtrusionSolverAttribute RotateAxisEnd [pwu::Vector3 add {0 0 0} {1 0 0}]
	$far_dom setExtrusionSolverAttribute RotateAngle 360
	$far_extr run $NZZ_ROT_STEP
	$far_extr end

	set far_dom_sp [$far_dom split -J [expr int($NZZ_ROT_STEP/2)+1]]

	set D_frontb_seg [pw::SegmentSpline create]
	$D_frontb_seg addPoint [[$FWH_curve_con2 getNode End] getXYZ]
	$D_frontb_seg addPoint [[[[[lindex $far_dom_sp 0] getEdge 2] getConnector 1] getNode End] getXYZ]

	set D_frontconb [pw::Connector create]
	$D_frontconb addSegment $D_frontb_seg

	$D_frontconb setDimension [$D_frontcon getDimension]

	$D_frontconb setDistribution 1 [[$D_frontcon getDistribution 1] copy]

	set D_sideb [pw::DomainStructured createFromConnectors [list $FWH_curve_con2 \
								$edgbot_con\
								$nzz_outblk_rbcon\
								[[[lindex $far_dom_sp 0] getEdge 3] getConnector 1]\
								$D_frontconb]]

	set D_sider [pw::DomainStructured createFromConnectors [list [lindex $D_con_sp 0] \
								$D_frontcon\
								[[[lindex $far_dom_sp 0] getEdge 2] getConnector 1]\
								$D_frontconb]]

	set D_sidel [pw::DomainStructured createFromConnectors [list [lindex $D_con_sp 1] \
								$D_frontcon\
								[[[lindex $far_dom_sp 1] getEdge 2] getConnector 1]\
								$D_frontconb]]

	set D_blkright [pw::BlockStructured createFromDomains \
			[list $D_sider $D_side $D_sider1 $D_sideb $nzz_tck_top\
			[[[lindex $nzz_outblk_sp 0] getFace 4] getDomain 1] [lindex $far_dom_sp 0]]]

	set D_blkleft [pw::BlockStructured createFromDomains \
			[list $D_sidel $D_side $D_sidel1 $D_sideb $nzz_tck_bot\
			[[[lindex $nzz_outblk_sp 1] getFace 4] getDomain 1] [lindex $far_dom_sp 1]]]

	#collecting BC | far2
	lappend domBCs(3) [[$D_blkright getFace 4] getDomain 1]
	lappend blkBCs(3) $D_blkright
	
	#collecting BC | nozzle
	lappend domBCs(0) [[$D_blkright getFace 2] getDomain 2]
	lappend blkBCs(0) $D_blkright
	
	#collecting BC | far2
	lappend domBCs(3) [[$D_blkleft getFace 4] getDomain 1]
	lappend blkBCs(3) $D_blkleft
	
	#collecting BC | nozzle
	lappend domBCs(0) [[$D_blkleft getFace 2] getDomain 2]
	lappend blkBCs(0) $D_blkleft

	# THIRD PART
	#-----------------------------------------------------------------------------
	# examine edge length
	set corejet_edg_exm [pw::Examine create ConnectorEdgeLength]
	$corejet_edg_exm addEntity [lindex $nzz_far_con_sp 0]
	$corejet_edg_exm examine
	set corejet_edg_value [$corejet_edg_exm getValue [lindex $nzz_far_con_sp 0] \
						[expr [[lindex $nzz_far_con_sp 0] getDimension]-1]]

	set corejet_face [pw::FaceStructured createFromDomains [list [lindex $D_inn_BLdom_sp 0] \
								[lindex $D_inn_BLdom_sp 1]\
								[lindex $D_inn_dom_sp 0]\
								[lindex $D_inn_dom_sp 1]]]

	set corejet_blk1 [pw::BlockStructured create]
	set corejet_blk2 [pw::BlockStructured create]
	$corejet_blk1 addFace [lindex $corejet_face 0]
	$corejet_blk2 addFace [lindex $corejet_face 1]
	set corejet_extr [pw::Application begin ExtrusionSolver [list $corejet_blk1 $corejet_blk2]]
	$corejet_blk1 setExtrusionSolverAttribute Mode Translate
	$corejet_blk1 setExtrusionSolverAttribute TranslateDirection {1 0 0}
	$corejet_blk1 setExtrusionSolverAttribute TranslateDistance 20
	$corejet_blk2 setExtrusionSolverAttribute Mode Translate
	$corejet_blk2 setExtrusionSolverAttribute TranslateDirection {1 0 0}
	$corejet_blk2 setExtrusionSolverAttribute TranslateDistance 20
	$corejet_extr run [expr int(floor(20/$corejet_edg_value))]
	$corejet_extr end
	
	#collecting BC | far3
	lappend domBCs(4) [[$corejet_blk1 getFace 6] getDomain 1]
	lappend blkBCs(4) $corejet_blk1

	#collecting BC | far3
	lappend domBCs(4) [[$corejet_blk2 getFace 6] getDomain 1]
	lappend blkBCs(4) $corejet_blk2

	set DD_front_seg [pw::SegmentSpline create]
	$DD_front_seg addPoint [[[lindex $nzz_far_con_sp 1] getNode End] getXYZ]
	$DD_front_seg addPoint \
		[[[[[[$corejet_blk1 getFace 3] getDomain 1] getEdge 2] getConnector 1] getNode End] getXYZ]

	set DD_front_con [pw::Connector create]
	$DD_front_con addSegment $DD_front_seg

	[lindex $nzz_far_con_sp 1] setDimension [expr int(floor(20/$corejet_edg_value))+1]
	$DD_front_con setDimension [$D_frontcon getDimension]
	$DD_front_con setDistribution 1 [[$D_frontcon getDistribution 1] copy]
	[$DD_front_con getDistribution 1] reverse

	set DD_side [pw::DomainStructured createFromConnectors [list [lindex $nzz_far_con_sp 1] \
						$D_frontcon \
						[[[[$corejet_blk1 getFace 3] getDomain 1] getEdge 2] getConnector 1]\
						$DD_front_con]]

	#revolve
	set DDface [pw::FaceStructured createFromDomains [list $DD_side]]
	set DD_outblk [pw::BlockStructured create]
	$DD_outblk addFace $DDface

	set DD_outblk_extr [pw::Application begin ExtrusionSolver [list $DD_outblk]]
	$DD_outblk setExtrusionSolverAttribute Mode Rotate
	$DD_outblk setExtrusionSolverAttribute RotateAxisStart {0 0 0}
	$DD_outblk setExtrusionSolverAttribute RotateAxisEnd [pwu::Vector3 add {0 0 0} {1 0 0}]
	$DD_outblk setExtrusionSolverAttribute RotateAngle 360
	$DD_outblk_extr run $NZZ_ROT_STEP
	$DD_outblk_extr end

	set DD_outblk_sp [$DD_outblk split -K [expr int(floor($NZZ_ROT_STEP/2))+1]]
	
	#collecting BC | far2
	lappend domBCs(3) [[[lindex $DD_outblk_sp 0] getFace 3] getDomain 1]
	lappend blkBCs(3) [lindex $DD_outblk_sp 0]

	#collecting BC | far3
	lappend domBCs(4) [[[lindex $DD_outblk_sp 0] getFace 2] getDomain 1]
        lappend blkBCs(4) [lindex $DD_outblk_sp 0]

	#collecting BC | far2
	lappend domBCs(3) [[[lindex $DD_outblk_sp 1] getFace 3] getDomain 1]
	lappend blkBCs(3) [lindex $DD_outblk_sp 1]

	#collecting BC | far3
	lappend domBCs(4) [[[lindex $DD_outblk_sp 1] getFace 2] getDomain 1]
        lappend blkBCs(4) [lindex $DD_outblk_sp 1]

	set dashes [string repeat - 70]

	puts "MULTI-BLOCK GRID WITHOUT FWH MARKER/INTERFACE GENERATED FOR LEVEL $res_lev."

	set blk [pw::Grid getAll -type pw::Block]
	
	return $blk

}
