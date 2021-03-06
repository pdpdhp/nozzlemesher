# =============================================================
# This script is written to generate structured multi-block
# grid for a nozzle profile with respect to grid guideline.
#==============================================================
# written by Pay Dehpanah
# last update: Sep 2021
#
#==============================================================

import numpy as np
import math
from pathlib import Path

import os
dirname = os.path.dirname(os.path.realpath(__file__))

Path(f"{dirname}").mkdir(parents=True, exist_ok=True)

#----------------------------GRID GUIDELINE FOR NOZZLE--------------------
#reynoldsnumbers
REYNOLDS_NUM = [1.0E6,1.0E6,1.0E6,1.0E6,1.0E6]
#
#
#machnumber
MACH = [0.9,0.9,0.9,0.9,0.9]
#
#
#TARGET Y PLUS FOR RANS AND HYBRID RANS/LES
TARG_YPR = [0.04488,0.08977,1.0,3.591,10.181]
#
#
#BOUNDARY BLOCK CELL GROWTH RATE
TARG_GR = [1.12,1.14,1.16,1.18,1.25]
#
#
#STORUHAL NUMBER
St = [18,16,14,12,10]
#
#
#POINTS PER WAVELENGTH
Nw = [56,36,20,12,8]
#
#
#PHASE SPEED 
UUP = [0.6,0.6,0.6,0.6,0.6]
#
#-------------------FLOW PROPERTISE BASED ON THE PAPER BY BRES------------
NUM_LEVR = len(TARG_YPR)
#-----------------PRESSURE/TEMPERATURE--------------
#NOZZLE TEMPERATURE RATIO
NTR=1.15
#NOZZLE PRESSURE RATIO
NPR=1.7

#-----------------MACH NUMBER-----------------
M= np.array(MACH)

#------------------Reynolds No.----------------
Re = np.array(REYNOLDS_NUM)

#-----------------FREESTREAM PRESSURE (Pa)----------------
PRESSURE = 101325.0
#
P = np.zeros(NUM_LEVR) + PRESSURE

#---------------REFERENCE LENGTH---------------
Ref_Length = 1.0

D=np.zeros(NUM_LEVR) + Ref_Length

#---------------GAS CONSTANT---------------
R=8314.4621
Rs=287.058
gama=1.4

#FLOW PROPERTISE BASED ON SUTHERLAND LAW
#----SUTHERLAND LAW FOR FLOW PROPERTISE----
mo0 = 1.716e-05
TEMP =  273.15
#
T0= np.zeros(NUM_LEVR) + TEMP

S = 110.4
Ts = T0*NTR

ypr=np.array(TARG_YPR)
gr=np.array(TARG_GR)
stno = np.array(St)
nwave = np.array(Nw)
uup = np.array(UUP)

#DYNAMIC/ABSOLUTE VISCOSITY based SUTHERLAND LAW
mos = mo0 * ((Ts/T0)**(3/2)) * ((T0 + S)/(Ts + S))

#-------DENSITY BASED ON SUTHERLAND ----------
ros = ((mos * Re)/(((gama*P*NPR)**0.5)*M*D))**2

#-----SOUND SPEED BASED ON SUTHERLAND---------
Cs = np.sqrt(gama*(P*NPR/ros))

#-------VELOCITY BASED ON SUTHERLAND----------
Vs = Cs*M

#-----REYNOLD CHECK BASED ON SUTHERLAND-------
Res = (ros*Vs*D)/mos

#------------y+ calculation--------------------
#scholchting_skin_friction
cf=(2*np.log10(Re)-0.65)**(-2.3)

#----------WALL SHEAR STRESS------------------
#BASED ON SUTHERLAND
ta_ws=cf*0.5*ros*(Vs**2)

#-----------FRICTION VELOCITY/U star----------------
uss=np.sqrt(ta_ws/ros)

#-----------FIRST CELL HEIGHT | DELTA S-------
dssr=(ypr*mos)/(ros*uss)


#FIXING REYNOLDS BASED ON VISOCOSITY
#---------------IDEAL GAS-------------------
ro=P*NPR/((R/28.966)*Ts)

#---------------SOUND SPEED----------------
C=np.sqrt(gama*(P*NPR/ro))

#---------------VELOCITY-------------------
V=C*M

#KINEMATIC VISCOSITY/MOMENTOM DIFFUSIVITY--
no=(V*D)/Re

#--------DYNAMIC/ABSOLUTE VISCOSITY--------
mo=ro*no

#-----------REYNOLDS CHECK -----
Re1=(ro*V*D)/mo

#FIXED RAYNOLDS
ta_w=cf*0.5*ro*(V**2)
us=np.sqrt(ta_w/ro)
dss=(ypr*mo)/(ro*us)

# AXIAL SPACING

CHR_SPC = (uup*D) / (nwave*stno)

# ---------- GRID PROPERTISE-----------------

axial_csize=np.array(CHR_SPC)

#------------------GRID PROPERTISE--------------

NUM_LEVR = len(TARG_YPR)

grid_spec=np.column_stack((ypr,dssr,gr,axial_csize[0:NUM_LEVR],stno[0:NUM_LEVR],nwave[0:NUM_LEVR],uup[0:NUM_LEVR]))

#------------------FLOW PROPERTISE--------------
#FLOW PROPERTISE BASED ON SUTHERLAND | SI

flow_spec_si=np.column_stack((Res[0:NUM_LEVR],D[0:NUM_LEVR],P[0:NUM_LEVR]*NPR,Ts[0:NUM_LEVR],ros[0:NUM_LEVR],M[0:NUM_LEVR]))

#------------writing files---------------------
# grid propertise metric
f = open(f'{dirname}/grid_specification.txt', 'w')
f.write("%7s %17s %9s %16s %9s %7s %7s\n" % ("Y+","Delta_S(m)","GR","N_Spacing(m)","Storuhal_Num","Nodes","Speed"))

for i in range(NUM_LEVR):
    f.write(" %1.3e   %1.7e   %1.3e   %1.3e      %3d         %3d      %1.1f\n" % (grid_spec[i,0],grid_spec[i,1],grid_spec[i,2],\
						grid_spec[i,3],grid_spec[i,4],grid_spec[i,5],grid_spec[i,6]))
f.close()

f = open(f'{dirname}/flow_propertise.txt', 'w')
f.write("%10s %14s %12s %12s %20s %10s \n" % ("Reynolds","Ref_length(m)","Pressure(Pa)","Temp(K)","Density(Kg/m3)","Mach"))

for i in range(NUM_LEVR):
    f.write("%1.5e  %1.5e %1.7e  %1.7e %1.15e  %1.5e\r\n" % (flow_spec_si[i,0],flow_spec_si[i,1],\
		flow_spec_si[i,2],flow_spec_si[i,3],flow_spec_si[i,4],flow_spec_si[i,5]))
f.close()


