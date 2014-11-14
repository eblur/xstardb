%%
%% Chandra_15yrs_ex1.sl : One of three examples for our poster at the
%%                        15 years of Chandra symposium
%%
%% Created 2014.11.11   : lia@space.mit.edu
%%

require("xstardb");

%%----------------------------------------------------------------
%% Example 1: A single photemis model

% Set up the model, with fits file writing
fit_fun( "photemis2(1)" );

set_par( "photemis2(1).write_outfile", 1 );
set_par( "photemis2(1).autoname_outfile", 1 );
set_par( [3:27], 0 );
set_par( "photemis2(1).Oabund", 1 );

% Run the model
variable x1, x2;
(x1, x2) = linear_grid( 1.0, 40.0, 10000 );
variable y = eval_fun( x1, x2 );

% Load the XSTAR database from this run
variable db = rd_xstar_output( "photemis_1.fits" );

% Plot the spectrum, 18 - 24 Angs
plot_bin_density;
xlabel( latex2pg( "Wavelength [\\A]" ) );
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
yrange(1.e-13, 1); ylog;
xrange(18, 24);
hplot( x1, x2, y, 1 );

% Find the strongest lines by luminosity
variable strongest = xstar_strong( 8, db; wmin=18.0, wmax=24.0 );

% Print a table of the strongest lines
xstar_page_group( db, strongest; sort="luminosity" );

% Mark them on the current plot
variable lstyle = line_label_default_style();
lstyle.top_frac = 0.85;
lstyle.bottom_frac = 0.7;
xstar_plot_group( db, strongest, 3, lstyle );




