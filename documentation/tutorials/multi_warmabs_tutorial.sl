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
hplot(x1,x2,y1,1);

%%----------------------------------------------------------------%%
%% 2. Load multiple datasets from the fits files

variable wa1 = rd_xstar_output("warmabs_1.fits");
variable wa2 = rd_xstar_output("warmabs_2.fits");

tic; superdb = xstar_load_tables(["warmabs_1.fits","warmabs_2.fits"]); toc;
% ~ 3.5






