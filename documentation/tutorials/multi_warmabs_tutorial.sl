%%%%
%% multi_warmabs_tutorial.sl
%% 2014.10.01 : lia@space.mit.edu
%%
%% This tutorial will show you how to navigate data from a
%% multi-component XSTAR models.
%%
%%%%

require("warmabs_db");

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

variable wa1 = rd_xstar_output("warmabs_1.fits");
variable wa2 = rd_xstar_output("warmabs_2.fits");

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
variable i1 = where( wa_all.origin_file[s_all] == 0 );
variable i2 = where( wa_all.origin_file[s_all] == 1 );

variable lstyle = line_label_default_style();
lstyle.top_frac = 0.8; 
lstyle.bottom_frac = 0.6;
lstyle.angle = 45;

% For model 1:
xstar_plot_group( wa_all, s_all[i1], 2, lstyle);

% For model 2, need to include redshift
xstar_plot_group( wa_all, s_all[i2], 3, lstyle, get_par("warmabs2(2).Redshift"));

%% If you wanted to correct the wavelength for redshift, do so before
%% combining the datasets
%
% wa2.wavelength *= (1.0 + get_par("warmabs2(2).Redshift"));
% wa_all = merge_xstar_output([wa1, wa2]);
%
% This will be more necessary if you are modeling something at large
% enough redshift (z >~ 0.1), which will affect your ability to
% identify lines in the model spectrum.

