# =============================================================
# This script is written to generate structured multi-block
# grid for a nozzle profile with respect to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#==============================================================

#               GRID REFINEMENT LEVEL:
#=====================================================
#Grid Levels vary from the first line (finest, level 0) of the grid_specification.txt to the last line (coarsest, level 4)!
set res_lev                         4;# From  0 (finest) to 4 (coarsest)

#GRID SYSTEM'S ARRANGEMENT: STRUCTURED 
#====================================================
#PLEASE SELECT GRID SYSTEM:
set GRD_TYP                       STR;# STR (for STRUCTURED)

# STRUCTURED SETTINGS:
#====================================================
#NOZZLE EXIT BOUNDARY LAYER THICKNESS
set NZZ_BLTK                     0.08;#

#STEPS IN RADIAL DIRECTION
set NZZ_ROT_STEP                   72;#

#SPONGE ZONE
#------------
#INSIDE GROWTH RATIO 
set Sponge_iGR                    1.1;#

#OUTSIDE GROWTH RATIO
set Sponge_oGR                    1.1;#

#FWH SURFACE SETTING
#-------------------
#FWH SURFACE SLOPE
set FWH_slp                       0.1;#

#FWH MARKER AXIAL GROWTH RATIO
set FWH_GR                      1.008;#

#GROWTH PERCENTAGE OF FWH MARKER GROWTH RATIO AFTER 5D(%)
set FWH_GRP                      10.0;#

#FWH Surface Approx Redius From (0,0,0) at Outlet
set FWH_R                       0.515;# FWH_R > 0.51

#CAE EXPORT:
#===================================================
#enables unmarked CAE export 
set unmarked_export               YES;# (YES/NO)

#enables CAE export with interfaced FWH surface 
set FWH_winterface_export         YES;# (YES/NO)

#CAE SOLVER SELECTION.
set cae_solver                    SU2;# FWHMarker.tcl script works only with SU2 format

#SAVES NATIVE FORMATS 
set save_native                   YES;# (YES/NO)

#-------------------------------------- GRID GUIDELINE--------------------------------------

#TARGET Y PLUS FOR RANS AND HYBRID RANS/LES
set TARG_YPR                           {0.04488,0.08977,1.0,3.591,10.181}

#BOUNDARY BLOCK CELL GROWTH RATE
set TARG_GR                                    {1.12,1.14,1.16,1.18,1.25}

#STORUHAL NUMBER
set St                                                   {18,16,14,12,10}

#POINTS PER WAVELENGTH
set Nw                                                    {56,36,20,12,8}

#PHASE SPEED
set UUP                                             {0.6,0.6,0.6,0.6,0.6}

#------------------------------------------------------------------------------------------
