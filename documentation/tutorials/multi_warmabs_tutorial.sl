%%%%
%% multi_warmabs_tutorial.sl
%% 2014.10.01 : lia@space.mit.edu
%%
%% This tutorial will show you how to navigate data from multiple
%% XSTAR models.  It will also show you how to run a grid of models,
%% stepping through values of some interesting parameter, and plot the
%% results.
%%
%%%%

require("warmabs_db");
require("multi_warmabs_db");
require("examples/warmabs_vs_xi_test.sl");

%%----------------------------------------------------------------%%
%% 1. Simulate a multi-component warm absorption model

% Absorber 1: Local (z=0) material
% Absorber 2: Fast outflow from MCG -6-30-15
% Inspiration : see Holczer et al. (2010) ApJ 708, 981
%
fit_fun("warmabs2(1) + warmabs2(2)");
% Note: warmabs2 is a modified warmabs model, allows for automatic output naming

% Set up models to automatically write output
set_par("warmabs2(*).write_outfile", 1);
set_par("warmabs2(*).autoname_outfile", 1);

set_par( "warmabs2(1).column", -1 ); % Log10(1.e20/1.e21) ??
set_par( "warmabs2(1).rlogxi", -1.0 ); % Guess
set_par( "warmabs2(1).vturb", 100.0 );
set_par( "warmabs2(1).Redshift", 0.0 );

set_par( "warmabs2(2).column", log10(8.1) );
set_par( "warmabs2(2).rlogxi", 3.8 );
set_par( "warmabs2(2).vturb", 500.0 );
set_par( "warmabs2(2).Redshift", 0.007749 );

list_par; % Check out the model settings

% Evaluate the model
variable x1, x2;
(x1, x2) = linear_grid( 1.0, 40.0, 8192 ); 
variable y1 = eval_fun(x1, x2);

% Plot it
plot_bin_density;
xlabel( latex2pg( "Wavelength [\\A]" ) ) ; 
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
ylog; 
yrange(200.0,500.0);
hplot(x1,x2,y1,1);

%%----------------------------------------------------------------%%
%% 2. Load multiple datasets from the fits files

%%%%%%%%%%%%%%%%%%%%%%%%% WORKING FROM HERE %%%%%%%%%%%%%%%%%%%%%%%

variable wa1 = rd_xstar_output("warmabs_1.fits");
variable wa2 = rd_xstar_output("warmabs_2.fits");

tic; 
variable grid = xstar_load_tables(["warmabs_1.fits","warmabs_2.fits"]); toc;
% ~ 3.5

% Without merging, new functions need to be created case-by-case to
% deal with an array of structures
%
variable test = xstar_wl_all([wa1,wa2], 7.0, 10.0);
xstar_page_all([wa1,wa2], test);

% merge_xstar_output creates a single database from two database functions
%
variable wa_all = merge_xstar_output( [wa1, wa2] );

%% Example: Find lines strongest lines within an interesting wl range
yrange();
xrange(7.0,10.0);
hplot(x1,x2,y1,1);

variable s_all = xstar_strong(5, wa_all; wmin=7.0, wmax=10.0);
xstar_page_group(wa_all, s_all; sort="ew");

%% Plot the lines
variable i1 = where( wa_all.origin_file[s_all] == "warmabs_1.fits" );
variable i2 = where( wa_all.origin_file[s_all] == "warmabs_2.fits" );

variable lstyle = line_label_default_style();
lstyle.top_frac = 0.8; 
ylstyle.bottom_frac = 0.6;
lstyle.angle = 45;

% For model 1:
xstar_plot_group( wa_all, s_all[i1], 2, lstyle);

% For model 2, need to include redshift
xstar_plot_group( wa_all, s_all[i2], 3, lstyle, get_par("warmabs2(2).Redshift"));

%% If you wanted to correct the wavelength for redshift, before
%% combining datasets, do the following.
%
% wa2.wavelength *= (1.0 + get_par("warmabs2(2).Redshift"));
% wa_all = merge_xstar_output([wa1, wa2]);
%
% This will be more necessary if you are modeling something at
% intermediate redshift, and need to identify lines in your model spectrum.


%%----------------------------------------------------------------%%
%% 3. Create a model grid by looping over an interesting parameter

%% Dave's code: run_models and mk_pfiles


%%----------------------------------------------------------------%%
%% 4. Load the model into a grid structure

%% Dave's code: xstar_load_tables


%% Desired functionality, from lia:

% 1. Find all lines in the grid within a certain wavelength range
%
% uids = xgrid_wl( t, wlo, whi );


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

