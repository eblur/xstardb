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

%%%%%%%%%%%%%%%%%%%%%%% working from here %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Dave's code: xstar_load_tables

%require("examples/warmabs_vs_xi_test");

% 0. Load data

variable fgrid, wa_grid;
fgrid = glob( "/vex/d1/lia/xstar_test/column/warmabs_*.fits" );
fgrid = fgrid[ array_sort(fgrid) ];

wa_grid = xstar_load_tables(fgrid);

% 1. Find all lines in the grid within a certain wavelength range
%
% uids = xgrid_wl( t, wlo, whi );

variable test = where( xstar_wl(wa_grid.mdb, 1.0, 2.0) );
xstar_page_grid( wa_grid, test );

%% Pick out a line
%variable k = 10;
%xstar_page_group( wa_grid.db[k], xstar_strong(5, wa_grid.db[k]; wmin=5, wmax=10) );

% I'll use Si VII
%variable line_ew = xstar_line_ew( 23156, "si_vii", wa_grid.db );

%ylin; yrange(); xrange();
%xlabel( latex2pg( "\log(N_H/10^{21})" ) );
%ylabel( latex2pg( "Equivalent Width [\\A]" ) );
%plot(wa_grid.par.column, line_ew, 2 );


%% Desired functionality, from lia:




% 2. Find all lines in a grid from a particular element or ion
%
% uids = xgrid_el_ion( t, el_list, ion_list );




% 3. View some basic information about the lines according to uid
%
% xstar_page_grid( t, uids );


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

