%%%%
%% grid_warmabs_tutorial.sl
%% 2014.10.15 : lia@space.mit.edu
%%
%% This tutorial will show you how to compute a grid of XSTAR models,
%% stepping over some interesting parameter.  It will show you how to
%% navigate the grid structure, which combines information from all
%% the databases, and how to plot properties of a particular
%% transition as it changes with the parameter of interest.
%%
%%%%

require("warmabs_db");
require("multi_warmabs_db");

%%----------------------------------------------------------------%%
%% 1. Create a model grid by looping over an interesting parameter

%% xstar_run_model_grid( info, rootdir[; nstart] );
%% Runs specified XSTAR model over a specific parameter
%%
%% INPUTS:
%% info      = struct{ bins, mname, pname, min, max, step }
%% info.grid = struct{ bin_lo, bin_hi, value }
%% rootdir   = string describing the root directory to dump all the files into
%% nstart    = an integer setting the first index on the output label

% This example runs a model grid over the column density parameter,
% from N_H = 1.e20 to 1.e22

variable warmabs_info = @_default_model_info;
set_struct_fields( warmabs_info, "warmabs", "column", -1.0, 1.0, 0.1, _default_binning );

% _default_binning is (bin_lo, bin_hi) = linear_grid( 1.0, 40.0, 8192 );

%variable swa;
%tic; swa = xstar_run_model_grid( warmabs_info, "/vex/d1/lia/xstar_test/column/"; nstart=10 ); toc;

%%----------------------------------------------------------------%%
%% 2. Load the model into a grid structure

variable fgrid, wa_grid;
fgrid = glob( "/vex/d1/lia/xstar_test/column/warmabs_*.fits" );
fgrid = fgrid[ array_sort(fgrid) ];

wa_grid = xstar_load_tables(fgrid);

%%----------------------------------------------------------------%%
%% 3. Navigate the grid by using common functions like xstar_wl and
%% xstar_el_ion on the "master database": wa_grid.mdb


%% Find all lines within a wavelength range

variable test = where( xstar_wl(wa_grid.mdb, 1.0, 2.0) );
xstar_page_grid( wa_grid, test );


%% Pick lines by wavelength, element, and ion

variable k = 10;
xstar_page_group( wa_grid.db[k], xstar_strong(5, wa_grid.db[k]; wmin=5, wmax=10) );

% I'll use a single Si VII line...
variable si7 = where( xstar_wl(wa_grid.mdb, 7.0, 8.0) and xstar_el_ion(wa_grid.mdb, Si, 7) );
xstar_page_grid( wa_grid, si7 );

% ...to look at a curve-of-growth
variable si7_ew  = xstar_line_prop( wa_grid, wa_grid.uids[si7[0]], "ew" );

% Look at the "par" field of wa_grid to get interesting parameters
variable log_col = log10( wa_grid.par.column ) / 22.0;

% Plot it up
ylin; yrange(); xrange();
xlabel( latex2pg( "\log(N_H/10^{22}\ cm^{-2})" ) );
ylabel( latex2pg( "Equivalent Width [\\A]" ) );
title("Si VII : " + wa_grid.mdb.lower_level[si7[0]] + " - " + wa_grid.mdb.upper_level[si7[0]] );
plot(log_col, si7_ew, 2 );


% 4. Get information from a single line
%
% aline = line_info( s, uid );  %<--- needs a different name
% Returns struct{ wavelength, Z, q, a_ij, type, ew, ...}
% Make this private?


% 5. Get information about a single line, from the entire grid
%
% grid_line = xgrid_line_info( t, uid );
% Returns an array of line_info structures


% Then you can get any field you want as a function of the grid parameter
% line_ew = array_struct_field( grid_line, "ew" );
% plot( t.param.rlogxi, line_ew );

