Nozzle Mesher
================================

Introduction
------------
These scripts written to generate structured grid with FWH marker.

Batch
-----
```shell
pointwise -b NZZmesher.glf ?MeshParameters.glf? profile.txt <Profile File>
```
GUI
---
![GUI](https://github.com/pdpdhp/nozzlemesher/blob/main/nzzmesherGUI.png)

FWH Marker
----------
To mark the FWH surface in SU2 format:
```shell
tclsh FWHMarker.tcl
```
