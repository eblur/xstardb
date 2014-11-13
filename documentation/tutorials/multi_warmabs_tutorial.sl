%%%%
%% multi_warmabs_tutorial.sl
%% 2014.10.01 : lia@space.mit.edu
%%
%% This tutorial will show you how to navigate data from a
%% multi-component XSTAR models.
%%
%%%%

_traceback = 1;  % helpful for debugging

require("xstardb");

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

% For sake of example, 
% I increased the redshift in comparison to paper
set_par( "warmabs2(2).Redshift", 0.1 ); 

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

% merge_xstar_output creates a single database from a list of filenames
%
variable wa_all = xstar_merge( ["warmabs_1.fits","warmabs_2.fits"] );

% Set up redshift array for searching the db
variable zvals = [get_par("warmabs2(1).Redshift"), get_par("warmabs2(2).Redshift")];

%%---
%% Find everything within a certain wavelength range

variable AMIN = 19.5;
variable AMAX = 22.0;

yrange();
xrange(AMIN, AMAX);
hplot(x1,x2,y1,1);

variable ll = where( xstar_wl(wa_all, AMIN, AMAX; redshift=zvals) );
xstar_page_group(wa_all, ll);
xstar_page_group(wa_all, ll; redshift=zvals);

% Plot lines from each model, respectively
variable l1 = ll[ where( wa_all.origin_file[ll] == 0 ) ];
variable l2 = ll[ where( wa_all.origin_file[ll] == 1 ) ];

variable lstyle = line_label_default_style();
lstyle.top_frac = 0.6; 
lstyle.bottom_frac = 0.8;
lstyle.angle = -45;

% For model 1:
xstar_plot_group( wa_all, l1, 2, lstyle, zvals[0]);

% For model 2, need to include redshift
xstar_plot_group( wa_all, l2, 3, lstyle, zvals[1]);


%%---
%% Choose the strongest transitions in the entire spectrum

variable ss = xstar_strong( 5, wa_all; redshift=zvals );
xstar_page_group( wa_all, ss; sort="ew", redshift=zvals );

% They are all within 1.5 and 2.5 Angstroms
xrange(1.5,2.5);
hplot(x1, x2, y1, 1);

% They are all from warmabs_2, so use just one plotting command
xstar_plot_group( wa_all, ss, 3, lstyle, zvals[1]);
