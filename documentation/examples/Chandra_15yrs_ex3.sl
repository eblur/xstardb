%%
%% Chandra_15yrs_ex3.sl : One of three examples from our poster at the
%%                        15 Years of Chandra symposium
%%
%% Created 2014.11.11   : lia@space.mit.edu
%%

require("xstardb");

%%----------------------------------------------------------------
%% Example 3: Run a grid of photemis models over rlogxi

%% 1. Set up the model parameters

variable x1, x2;
(x1, x2) = linear_grid( 1.0, 40.0, 10000 );

variable model_info    = @_default_model_info;
variable model_binning = struct{ bin_lo=x1, bin_hi=x2 };

set_struct_fields( model_info, "photemis", "rlogxi", -2.0, 2.0, 0.1, model_binning );

%% WARNING: This will take awhile (~20 minutes on my machine)
%% Comment out the line below if you have already run the model grid
%xstar_run_model_grid( model_info, "/vex/d1/lia/rlogxi_example/"; nstart=10 );
%% ^If you are running more than 10 models, you should choose a
%% double-digit number for nstart, so the filenames can be sorted
%% properly by array_sort (below)


%% 2. Load the models into a gridded database structure
variable fgrid, pe_grid;

fgrid = glob( "/nfs/vex/d1/lia/rlogxi_example/photemis_*.fits" );
fgrid = fgrid[ array_sort(fgrid) ];

pe_grid = xstar_load_tables( fgrid );


%% 3. Look for the o_vii triplet

variable o_vii = where( xstar_el_ion(pe_grid.mdb, O, 7) );
xstar_page_grid( pe_grid, o_vii );

%% Let's track the luminosity of the forbidden line as it changes with rlogxi
variable o_vii_F = where(xstar_trans( pe_grid.mdb, O, 7, 1, 2 ));
variable o_vii_F_lum = xstar_line_prop( pe_grid, o_vii_F, "luminosity" );
variable rlogxi  = xstar_get_grid_par( pe_grid, "rlogxi" );

% Plot it
xlabel( latex2pg( "rlog\\xi" ) );
ylabel( latex2pg( "Luminosity [10^{38} cgs]" ) );
title( pe_grid.mdb.transition_name[o_vii_F][0] );
plot( rlogxi, o_vii_F_lum, 3 );




