# Noah-OWP-Modular New Variables in Namelist

+ fsno - fraction of watershed covered by snow [-]
+ bdsno - bulk density of snow kg/m^3
+ sneqv - snow water equivalent [mm]
+ stc - snow and soil temperature. items 1,2,3 are snow temperatures. If initialized with a 0 and there should be a snow layer, this will potentially tank the TG value in initial iterations
+ tg - ground temperature [K]
+ snice - layer snow ice [mm] (3 values)
+ snliq - layer snow water [mm] (3 values)

## If this is a hot start:
Feed your values from a previous model spin up into namelist.input.newvars, and run : ln -s namelist.input namelist.input.newvars


## Guidance on how to estimate snice/snliq/stc (will require some pen and paper) if this is a 'cold start':
Take bdsno and sneqv and divide : snowh = sneqv/bdsno [now in meters]

If snowh is less than 0.025 m, do not set any variables snow temperature or snow liquid content.

### If snowh is between 0.05 and 0.025 m (XX is value estimate):
+ stc = 0.0, 0.0, XX
+ snice = 0.0, 0.0, XX
+ snliq = 0.0, 0.0, XX

### If snowh is between 0.025 and 0.25 m (XX is value estimate):
+ stc = 0.0, XX, XX
+ snice = 0.0, XX, XX
+ snliq = 0.0, XX, XX

### If snowh is above 0.25 m (XX is value estimate):
+ stc = XX, XX, XX
+ snice = XX, XX, XX
+ snliq = XX, XX, XX

### Snice & Snliq:
estimates are based on a mm value per layer, so an estimate of the individual layers are needed. To do this: first determine how large the 3rd layer (closest to the ground) [DZ_3rd] is (max should be 0.025 m) and follow:
```
SNICE_3 = X * DZ_3rd*(sneqv/SNOWH)
SLIQ_3 = (1-X) * DZ_3rd*(sneqv/SNOWH)
```
Determine DZ_2nd [if there is one], which will be min(SNOWH - 0.025, 0.25 - 0.025), and follow the same procedure:
```
SNICE_2 = X * DZ_2nd*(sneqv/SNOWH)
SLIQ_2 = (1-X) * DZ_2nd*(sneqv/SNOWH)
```
Determine DZ_1st, which is SNOWH - 0.025 - 0.25, and follow the same:
```
SNICE_1 = X * DZ_1st*(sneqv/SNOWH)
SLIQ_1 = (1-X) * DZ_1st*(sneqv/SNOWH)
```

+ X = fraction [0-1] of snow layer that is ice
+ 1 - X = fraction of snow layer that is water.

The value of X and 1-X may change per layer in initialization, and will likely be different for each layer if this is a hot start with snow present.

### Note on snow initialization from normal Noah-MP:
Snow is always initialized with full ice, meaning that snliq would be 0.0 for ALL layers and snice would be the snow ice (X = 1)
