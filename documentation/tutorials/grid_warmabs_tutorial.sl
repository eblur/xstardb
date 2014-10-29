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


%% Pick transitions by ion, e.g., O VII
variable o_vii = where( xstar_el_ion(wa_grid.mdb, O, 7) );
xstar_page_grid( wa_grid, o_vii; sort="a_ij" );

% The first one in the list -- resonance line from O VII triplet -- is strongest.
% I'll pick out the O VII triplet first

variable o_vii_triplet = where( xstar_trans(wa_grid.mdb, O, 7, 1, [2:7]) );
xstar_page_grid( wa_grid, o_vii_triplet; sort="a_ij");

% Pick out the resonance line
variable o_vii_R = where( xstar_trans(wa_grid.mdb, O, 7, 1, 7) );
xstar_page_grid( wa_grid, o_vii_R );

% Look at a curve-of-growth for this line
variable o_vii_R_ew  = xstar_line_prop( wa_grid, o_vii_R, "ew" );

% Look at the "par" field of wa_grid to get interesting parameters
variable log_col = log10( wa_grid.par.column ) / 22.0;

% Want
%variable log_col = xstar_get_par(wa_grid, "column");

% Plot it up
ylin; yrange(); xrange();
xlabel( latex2pg( "\log(N_H/10^{22}\ cm^{-2})" ) );
ylabel( latex2pg( "Equivalent Width [\\A]" ) );
title( wa_grid.mdb.transition_name[o_vii_R][0] );
plot(log_col, o_vii_R_ew, 2 );


% 5. Get information about a single line, from the entire grid?
%
% grid_line = xstar_line_info( t, uid );
% Returns an array of line_info structures


% Then you can get any field you want as a function of the grid parameter
% line_ew = array_struct_field( grid_line, "ew" );
% plot( t.param.rlogxi, line_ew );

