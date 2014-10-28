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

variable wa1 = rd_xstar_output("warmabs_1.fits");
variable wa2 = rd_xstar_output("warmabs_2.fits");

% merge_xstar_output creates a single database from two database functions
%
variable wa_all = xstar_merge( [wa1, wa2] );

%% Example: Find lines strongest lines within an interesting wl range
variable AMIN = 19.5;
variable AMAX = 22.0;

yrange();
xrange(AMIN, AMAX);
hplot(x1,x2,y1,1);


variable s_all = xstar_strong(5, wa_all; wmin=AMIN, wmax=AMAX );
xstar_page_group(wa_all, s_all; sort="ew");

%%---
%% NOTE : XSTAR model runs are calculated for the rest frame, but 
%% one of the absorbers in our model has z = 0.1
%%
%% When we run xstar_strong, the database will be searched for rest frame wavelengths.
%%
%% There are two ways one can manage this:

%%---
%% A. Search each database separately

variable s1 = xstar_strong(5, wa1; wmin=AMIN, wmax=AMAX );
xstar_page_group(wa1, s1; sort="ew");

variable s2 = xstar_strong(5, wa2; wmin=AMIN, wmax=AMAX, 
                           redshift=get_par("warmabs2(2).Redshift"));
xstar_page_group(wa2, s2; sort="ew");


variable lstyle = line_label_default_style();
lstyle.top_frac = 0.8; 
lstyle.bottom_frac = 0.6;
lstyle.angle = 45;

% For model 1:
xstar_plot_group( wa1, s1, 2, lstyle);

% For model 2, need to include redshift
xstar_plot_group( wa2, s2, 3, lstyle, get_par("warmabs2(2).Redshift") );

%% This doesn't look so great, so method B is probably better.

%%---
%% B. Adjust wavelength of the redshifted databases before combining

wa2.wavelength *= (1.0 + get_par("warmabs2(2).Redshift"));

variable wa_all_B = xstar_merge( [wa1, wa2] );

variable s_all = xstar_strong( 10, wa_all_B; wmin=AMIN, wmax=AMAX );
xstar_page_group( wa_all_B, s_all; sort="ew" );

variable i1 = where( wa_all_B.origin_file[s_all] == 0 );
variable i2 = where( wa_all_B.origin_file[s_all] == 1 );

hplot(x1, x2, y1, 1);
xstar_plot_group( wa_all_B, s_all[i1], 2, lstyle);
xstar_plot_group( wa_all_B, s_all[i2], 3, lstyle);

%%---
%% DEBUG this -- what are those lines around 19.8 - 20.4 Angs?
%% What about 20.5 - 21 Angs?

variable test1 = where( xstar_wl( wa1, AMIN, AMAX ) );
xstar_page_group( wa1, test1 );

variable test2 = where( xstar_wl( wa2, AMIN, AMAX ) );
xstar_page_group( wa2, test2 );

%% plot them all, and you can see ... there are a lot of lines missing!
hplot(x1, x2, y1, 1);
xstar_plot_group(wa1, test1, 2);
xstar_plot_group(wa2, test2, 3);
