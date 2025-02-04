! module for executing Noah-OWP-Modular model in a streamlined way

module RunModule

  use NamelistRead
  use LevelsType
  use DomainType
  use OptionsType
  use ParametersType
  use WaterType
  use ForcingType
  use EnergyType
  use AsciiReadModule
  use OutputModule
  use UtilitiesModule
  use ForcingModule
  use InterceptionModule
  use EnergyModule
  use WaterModule
  use DateTimeUtilsModule

  implicit none
  type :: noahowp_type
    type(namelist_type)   :: namelist
    type(levels_type)     :: levels
    type(domain_type)     :: domain
    type(options_type)    :: options
    type(parameters_type) :: parameters
    type(water_type)      :: water
    type(forcing_type)    :: forcing
    type(energy_type)     :: energy
  end type noahowp_type
contains

  !== Initialize the model ================================================================================

  SUBROUTINE initialize_from_file (model, config_filename)
    implicit none

    type(noahowp_type), target, intent(out) :: model
    character(len=*), intent (in)           :: config_filename    ! config file from command line argument
    integer             :: forcing_timestep         ! integer time step (set to dt) for some subroutine calls
    integer             :: IZ, trigger_recalc, location_error ! snow constants ! aaron a.


    associate(namelist   => model%namelist,   &
              levels     => model%levels,     &
              domain     => model%domain,     &
              options    => model%options,    &
              parameters => model%parameters, &
              water      => model%water,      &
              forcing    => model%forcing,    &
              energy     => model%energy)

      !---------------------------------------------------------------------
      !  initialize
      !---------------------------------------------------------------------
      call namelist%ReadNamelist(config_filename)

      call levels%Init
      call levels%InitTransfer(namelist)

      call domain%Init(namelist)
      call domain%InitTransfer(namelist)

      call options%Init()
      call options%InitTransfer(namelist)

      call parameters%Init(namelist)
      call parameters%paramRead(namelist)

      call forcing%Init(namelist)
      call forcing%InitTransfer(namelist)

      call energy%Init(namelist)
      call energy%InitTransfer(namelist)

      call water%Init(namelist)
      call water%InitTransfer(namelist)

      ! Initializations
      ! for soil water
      !water%zwt       = -100.0       ! should only be needed for run=1
      water%smcwtd    = 0.0          ! should only be needed for run=5
      water%deeprech  = 0.0          ! should only be needed for run=5
      water%qinsur    = 0.0          !
      water%runsrf    = 0.0          !
      water%runsub    = 0.0          !
      water%qdrain    = 0.0          !
      water%wcnd      = 0.0          !
      water%fcrmax    = 0.0          !
      water%snoflow   = 0.0          ! glacier outflow for all RUNSUB options, [mm/s]
      water%qseva     = 0.0          ! soil evaporation [mm/s]
      water%etrani    = 0.0          ! transpiration from each level[mm/s]
      water%btrani    = 0.0          ! soil water transpiration factor (0 to 1) by soil layer
      water%btran     = 0.0          ! soil water transpiration factor (0 to 1)

      ! for canopy water
      water%RAIN      = 0.0          ! rainfall mm/s
      water%SNOW      = 0.0          ! snowfall mm/s
      water%BDFALL    = 0.0          ! bulk density of snowfall (kg/m3)
      water%FB_snow   = 0.0          ! canopy fraction buried by snow (computed from phenology)
      water%FP        = 1.0          ! fraction of the gridcell that receives precipitation
      water%CANLIQ    = 0.0          ! canopy liquid water [mm]
      water%CANICE    = 0.0          ! canopy frozen water [mm]
      water%FWET      = 0.0          ! canopy fraction wet or snow
      water%CMC       = 0.0          ! intercepted water per ground area (mm)
      water%QINTR    = 0.0           ! interception rate for rain (mm/s)
      water%QDRIPR   = 0.0           ! drip rate for rain (mm/s)
      water%QTHROR   = 0.0           ! throughfall for rain (mm/s)
      water%QINTS    = 0.0           ! interception (loading) rate for snowfall (mm/s)
      water%QDRIPS   = 0.0           ! drip (unloading) rate for intercepted snow (mm/s)
      water%QTHROS   = 0.0           ! throughfall of snowfall (mm/s)
      water%QRAIN    = 0.0           ! rain at ground srf (mm/s) [+]
      water%QSNOW    = 0.0           ! snow at ground srf (mm/s) [+]
      water%SNOWHIN  = 0.0           ! snow depth increasing rate (m/s)
      water%ECAN     = 0.0           ! evap of intercepted water (mm/s) [+]
      water%ETRAN    = 0.0           ! transpiration rate (mm/s) [+]


      ! for snow water
      water%QVAP     = 0.0           ! evaporation/sublimation rate mm/s
      water%ISNOW    = 0
      water%SNOWH    = 0.0
      water%SNEQV    = 0.0
      water%SNEQVO   = 0.0
      !water%BDSNO    = 0.0          !snow average density [kg/m^3] aaron a. (now initilized by user )
      water%PONDING  = 0.0
      water%PONDING1 = 0.0
      water%PONDING2 = 0.0
      water%QSNBOT   = 0.0
      water%QSNFRO   = 0.0
      water%QSNSUB   = 0.0
      water%QDEW     = 0.0
      water%QSDEW    = 0.0
      !water%SNICE    = 0.0         !snow layer ice [mm] aaron a. (now initialized by user)
      !water%SNLIQ    = 0.0         !snow layer water [mm] aaron a. (now initialized by user)
      water%FICEOLD  = 0.0
      !water%FSNO     = 0.0          !fraction of grid square covered by snow [-] aaron a. (now initialized by user)

      ! for energy-related variable
      energy%TV      = 298.0        ! leaf temperature [K] !this is immediatly changed due to iteration
      !energy%TG      = 298.0       ! ground temperature [K] aaron a. (now initilized by user) [though will immediatly be changed by iteration]
      energy%CM      = 0.0          ! momentum drag coefficient
      energy%CH      = 0.0          ! heat drag coefficient
      energy%FCEV    = 5.0          ! constant canopy evaporation (w/m2) [+ to atm ]
      energy%FCTR    = 5.0          ! constant transpiration (w/m2) [+ to atm]
      energy%IMELT   = 1 ! freeze
      !energy%STC     = 298.0       ! soil/snow temperature [K] aaron a. (now initilized by user)
      energy%COSZ    = 0.7        ! cosine of solar zenith angle
      energy%ICE     = 0          ! 1 if sea ice, -1 if glacier, 0 if no land ice (seasonal snow)
      energy%ALB     = 0.6        ! initialize snow albedo in CLASS routine
      energy%ALBOLD  = 0.6        ! initialize snow albedo in CLASS routine
      energy%FROZEN_CANOPY = .false. ! used to define latent heat pathway
      energy%FROZEN_GROUND = .false.

      ! -- forcings
      ! these are initially set to huge(1) -- to trap errors may want to set to a recognizable flag if they are
      !   supposed to be assigned below (eg -9999)
      !forcing%UU       = 0.0        ! wind speed in u direction (m s-1)
      !forcing%VV       = 0.0        ! wind speed in v direction (m s-1)
      !forcing%SFCPRS   = 0.0        ! pressure (pa)
      !forcing%SFCTMP   = 0.0        ! surface air temperature [k]
      !forcing%Q2       = 0.0        ! mixing ratio (kg/kg)
      !forcing%PRCP     = 0.0        ! convective precipitation entering  [mm/s]    ! MB/AN : v3.7
      !forcing%SOLDN    = 0.0        ! downward shortwave radiation (w/m2)
      !forcing%LWDN     = 0.0        ! downward longwave radiation (w/m2)

      ! forcing-related variables
      forcing%PRCPCONV = 0.0        ! convective precipitation entering  [mm/s]    ! MB/AN : v3.7
      forcing%PRCPNONC = 0.0        ! non-convective precipitation entering [mm/s] ! MB/AN : v3.7
      forcing%PRCPSHCV = 0.0        ! shallow convective precip entering  [mm/s]   ! MB/AN : v3.7
      forcing%PRCPSNOW = 0.0        ! snow entering land model [mm/s]              ! MB/AN : v3.7
      forcing%PRCPGRPL = 0.0        ! graupel entering land model [mm/s]           ! MB/AN : v3.7
      forcing%PRCPHAIL = 0.0        ! hail entering land model [mm/s]              ! MB/AN : v3.7
      forcing%THAIR    = 0.0        ! potential temperature (k)
      forcing%QAIR     = 0.0        ! specific humidity (kg/kg) (q2/(1+q2))
      forcing%EAIR     = 0.0        ! vapor pressure air (pa)
      forcing%RHOAIR   = 0.0        ! density air (kg/m3)
      forcing%SWDOWN   = 0.0        ! downward solar filtered by sun angle [w/m2]
      forcing%FPICE    = 0.0        ! fraction of ice                AJN
      forcing%JULIAN   = 0.0        ! Setting arbitrary julian day
      forcing%YEARLEN  = 365        ! Setting year to be normal (i.e. not a leap year)
      forcing%FOLN     = 1.0        ! foliage nitrogen concentration (%); for now, set to nitrogen saturation
      forcing%TBOT     = 285.0      ! bottom condition for soil temperature [K]

      !! a reconstruction of the SNOW INIT that is in Noah-MP that was originally
      !! removed by OWP. For full, original code, please see:
      !! https://github.com/NCAR/noahmp/blob/master/drivers/wrf/module_sf_noahmpdrv.F
      !! ~line 2236
      !! Begin code changes (Aaron A.)

      ! filling snow water equivelant
      trigger_recalc = 0
      do IZ = -2, 0
        water%SNEQV = water%SNEQV + water%SNICE(IZ) + water%SNLIQ(IZ)
      end do

      if ((water%SNEQV <= 0.0).AND. (water%BDSNO <= 0.0)) then
        if (energy%stc(0) > 0.0) then
           write(*,'(A)') 'ERROR: Problem with snow water equivelant, snow density, and snow temperature assignment. Either remove the snow layer temperature (STC) or increase snow water equivelant and snow density .'
          stop
        else if ((water%snice(0) > 0.0).or.(water%snliq(0) > 0.0)) then
            write(*,'(A)') 'ERROR: Problem with snow water equivelant, snow density, and snow ice/water contenct (SNICE and SNLIQ). Either set SNICE and SNLIQ to zero in namelist or increase snow water equivelant and snow density .'
           stop
        end if
        ! if no snow intilized, set everything to 0
        water%snowh = 0.0
        water%sneqv = 0.0
        water%bdsno = 0.0
        domain%zsnso(-namelist%nsnow+1:0) = 0.0 ! comment out Aaron A.

      else ! else for the snow being initlized
      water%SNOWH = water%SNEQV/water%BDSNO ! snow depth, in m

      if( water%SNOWH < 0.025) then
        water%ISNOW = 0
        domain%dzsnso(-namelist%nsnow+1:0) = 0.0
      else
        if(( water%SNOWH >= 0.025) .AND. (water%SNOWH <= 0.05)) then
          water%ISNOW = -1
          domain%dzsnso(0) = water%SNOWH
        else if (( water%SNOWH > 0.05) .AND. (water%SNOWH <= 0.10)) then
          water%ISNOW = -2
          domain%dzsnso(-1) = water%SNOWH/2
          domain%dzsnso(0) = water%SNOWH/2
        else if (( water%SNOWH > 0.10) .AND. (water%SNOWH <= 0.25)) then
          water%ISNOW = -2
          domain%dzsnso(-1) = 0.05
          domain%dzsnso(0) = water%SNOWH - domain%dzsnso(-1)
        else if (( water%SNOWH > 0.25) .AND. (water%SNOWH <= 0.45)) then
          water%ISNOW = -3
          domain%dzsnso(-2) = 0.05
          domain%dzsnso(-1) = 0.5*(water%SNOWH - domain%dzsnso(-2))
          domain%dzsnso(0) = 0.5*(water%SNOWH - domain%dzsnso(-2))
        else if ( water%SNOWH > 0.45)  then
          water%ISNOW = -3
          domain%dzsnso(-2) = 0.05
          domain%dzsnso(-1) = 0.20
          domain%dzsnso(0) = water%SNOWH - domain%dzsnso(-2) - domain%dzsnso(-1)
        else
          write(*,'(A)') 'ERROR: Problem with the logic assigning snow layers.'
          stop
        end if !first nest
      end if ! second nest

      ! add a check due to some funky stuff with ISNOW and snow depths
      do IZ = water%ISNOW+1, 0
        if ((water%snice(IZ)==0).and.(water%snliq(IZ)==0)) then
            write(*,'(A)') 'WARNING: There is problem between the calculation snow height and user specified SNICE, SNLIQ, and BDSNO, with the snow height calculated being higher than the input'
            write(*,'(A)') 'We assume that the user specifcation is correct, and adjust snow initilization accordingly'
            trigger_recalc = 1
            location_error = IZ
            exit !exit and adjust
        end if ! end final initiliztion check
      end do ! end for loop

      if (trigger_recalc == 1) then ! we have to recalcualte

        if( location_error-1 == -1) then ! we have calculated 1 layer, but specified 0
          water%SNOWH = 0.025
          water%ISNOW = 0
          domain%dzsnso(-namelist%nsnow+1:0) = 0.0
        else if (location_error-1 == -2) then ! we have calculated 2 layers, but specified 1
          water%ISNOW = -1
          water%SNOWH = 0.05
          domain%dzsnso(-2) = 0.0
          domain%dzsnso(-1) = 0.0
          domain%dzsnso(0) = water%SNOWH
        else if (location_error-1 == -3) then ! we have calculated 3 layers, but specified 2
          water%ISNOW = -2
          water%SNOWH = 0.25
          domain%dzsnso(-2) = 0.0
          domain%dzsnso(-1) = 0.05
          domain%dzsnso(0) = 0.20
        end if
      end if ! end trigger check for snow depths
      
      ! now assign layer depths (zsnso) ! always 0 and -1
        domain%zsnso(water%ISNOW+1) = domain%dzsnso(water%ISNOW+1)

        if (water%isnow <= -2) then ! are there -2 or -3 layers
          domain%zsnso(water%isnow+2) = domain%dzsnso(water%isnow+2) + domain%zsnso(water%ISNOW+1)
          if (water%isnow == -3) then ! is there a -3 layer
            domain%zsnso(water%isnow+3) = domain%dzsnso(water%isnow+3) + domain%zsnso(water%ISNOW+2)
          end if
        end if

     end if ! end the check
     !! end the changes made by Aaron A.

      ! domain variables
      !domain%zsnso(-namelist%nsnow+1:0) = 0.0 ! comment out Aaron A.
      domain%zsnso(1:namelist%nsoil)    = namelist%zsoil

      ! time variables
      domain%nowdate   = domain%startdate ! start the model with nowdate = startdate
      forcing_timestep = domain%dt        ! integer timestep for some subroutine calls
      domain%itime     = 1                ! initialize the time loop counter at 1
      domain%time_dbl  = 0.d0             ! start model run at t = 0

      !---------------------------------------------------------------------
      !--- set a time vector for simulation ---
      !---------------------------------------------------------------------
      ! --- AWW:  calculate start and end utimes & records for requested station data read period ---
      call get_utime_list (domain%start_datetime, domain%end_datetime, domain%dt, domain%sim_datetimes)  ! makes unix-time list for desired records (end-of-timestep)
      domain%ntime = size (domain%sim_datetimes)
      !print *, "---------";
      !print *, 'Simulation startdate = ', domain%startdate, ' enddate = ', domain%enddate, ' dt(sec) = ', domain%dt, ' ntimes = ', domain%ntime  ! YYYYMMDD dates
      !print *, "---------"

      !---------------------------------------------------------------------
      ! Open the forcing file
      ! Code adapted from the ASCII_IO from NOAH-MP V1.1
      ! Compiler directive NGEN_FORCING_ACTIVE to be defined if
      ! Nextgen forcing is being used (https://github.com/NOAA-OWP/ngen)
      !---------------------------------------------------------------------
#ifndef NGEN_FORCING_ACTIVE
      call open_forcing_file(namelist%forcing_filename)
#endif

      !---------------------------------------------------------------------
      ! create output file and add initial values
      ! Compiler directive NGEN_OUTPUT_ACTIVE to be defined if
      ! Nextgen is writing model output (https://github.com/NOAA-OWP/ngen)
      !---------------------------------------------------------------------
#ifndef NGEN_OUTPUT_ACTIVE
      call initialize_output(namelist%output_filename, domain%ntime, levels%nsoil, levels%nsnow)
#endif

    end associate ! terminate the associate block

  END SUBROUTINE initialize_from_file

  !== Finalize the model ================================================================================

  SUBROUTINE cleanup(model)
    implicit none
    type(noahowp_type), intent(inout) :: model

      !---------------------------------------------------------------------
      ! Compiler directive NGEN_OUTPUT_ACTIVE to be defined if
      ! Nextgen is writing model output (https://github.com/NOAA-OWP/ngen)
      !---------------------------------------------------------------------
#ifndef NGEN_OUTPUT_ACTIVE
      call finalize_output()
#endif

  END SUBROUTINE cleanup

  !== Move the model ahead one time step ================================================================

  SUBROUTINE advance_in_time(model)
    type (noahowp_type), intent (inout) :: model

    call solve_noahowp(model)

    model%domain%itime    = model%domain%itime + 1 ! increment the integer time by 1
    model%domain%time_dbl = dble(model%domain%time_dbl + model%domain%dt) ! increment model time in seconds by DT
  END SUBROUTINE advance_in_time

  !== Run one time step of the model ================================================================

  SUBROUTINE solve_noahowp(model)
    type (noahowp_type), intent (inout) :: model
    integer, parameter :: iunit        = 10 ! Fortran unit number to attach to the opened file
    integer            :: forcing_timestep  ! integer time step (set to dt) for some subroutine calls
    integer            :: ierr              ! error code for reading forcing data
    integer            :: curr_yr, curr_mo, curr_dy, curr_hr, curr_min, curr_sec  ! current UNIX timestep details

    associate(namelist => model%namelist, &
              levels     => model%levels, &
              domain     => model%domain, &
              options    => model%options, &
              parameters => model%parameters, &
              water      => model%water, &
              forcing    => model%forcing, &
              energy     => model%energy)

    ! Compute the current UNIX datetime
    domain%curr_datetime = domain%sim_datetimes(domain%itime)     ! use end-of-timestep datetimes  because initial var values are being written
    call unix_to_date (domain%curr_datetime, curr_yr, curr_mo, curr_dy, curr_hr, curr_min, curr_sec)
    ! print '(2x,I4,1x,I2,1x,I2,1x,I2,1x,I2)', curr_yr, curr_mo, curr_dy, curr_hr, curr_min ! time check for debugging

    !---------------------------------------------------------------------
    ! Read in the forcing data
    ! Compiler directive NGEN_FORCING_ACTIVE to be defined if
    ! Nextgen forcing is being used (https://github.com/NOAA-OWP/ngen)
    ! If it is defined, Nextgen MUST provide forcing
    !---------------------------------------------------------------------
    forcing_timestep = domain%dt
#ifndef NGEN_FORCING_ACTIVE
    call read_forcing_text(iunit, domain%nowdate, forcing_timestep, &
         forcing%UU, forcing%VV, forcing%SFCTMP, forcing%Q2, forcing%SFCPRS, forcing%SOLDN, forcing%LWDN, forcing%PRCP, ierr)
#endif

    !---------------------------------------------------------------------
    ! call the main utility routines
    !---------------------------------------------------------------------
    call UtilitiesMain (domain%itime, domain, forcing, energy)

    !---------------------------------------------------------------------
    ! call the main forcing routines
    !---------------------------------------------------------------------

    call ForcingMain (options, parameters, forcing, energy, water)

    !---------------------------------------------------------------------
    ! call the main interception routines
    !---------------------------------------------------------------------

    call InterceptionMain (domain, levels, options, parameters, forcing, energy, water)

    !---------------------------------------------------------------------
    ! call the main energy balance routines
    !---------------------------------------------------------------------

    call EnergyMain (domain, levels, options, parameters, forcing, energy, water)

    !---------------------------------------------------------------------
    ! call the main water routines (canopy + snow + soil water components)
    !---------------------------------------------------------------------

    call WaterMain (domain, levels, options, parameters, forcing, energy, water)

    !---------------------------------------------------------------------
    ! add to output file
    ! Compiler directive NGEN_OUTPUT_ACTIVE to be defined if
    ! Nextgen is writing model output (https://github.com/NOAA-OWP/ngen)
    !---------------------------------------------------------------------
#ifndef NGEN_OUTPUT_ACTIVE
    call add_to_output(domain, water, energy, forcing, domain%itime, levels%nsoil,levels%nsnow)
#endif

    end associate ! terminate associate block
  END SUBROUTINE solve_noahowp

end module RunModule
