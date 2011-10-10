
You only need to use this update disk to update AMOEBA if you
have old versions of AMOEBA/PROSE and encounter incompatibilities.

This disk contains old versions of PROSE / FPGACFG which should run
on any version of AMOEBA. In general, try the FPGACFG.EZP command
direct from your normal PROSE disk first.

EG:-

"FPGACFG L" - to list the EEPROM slot contents

"FPGACFG W x filename.bin" to upload config 'filename.bin' to slot x"

"FPGACFG C x" - to configure from slot x (non-permanent)

"FPGACFG B x" - to make slot x the power-on boot slot.