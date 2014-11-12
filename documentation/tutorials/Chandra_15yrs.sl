%%
%% Chandra_15yrs.sl - Three examples from our poster at the 15 years
%%                    of Chandra symposium
%% 2014.11.11 : lia@space.mit.edu
%%

require("warmabs_db");

%%----------------------------------------------------------------
%% Example 1: A single warmabs model

% Set up the model, with fits file writing
fit_fun( "Powerlaw(1) * warmabs2(1)" );

set_par( "warmabs2(1).write_outfile", 1 );
set_par( "warmabs2(1).autoname_outfile", 1 );

% Run the model
variable x1, x2;
(x1, x2) = linear_grid( 1.0, 40.0, 10000 );
variable y = eval_fun( x1, x2 );

% Load the XSTAR database from this run
variable db = rd_xstar_output( "warmabs_1.fits" );

% Plot the spectrum, 21 - 23, Angs
plot_bin_density;
xlabel( latex2pg( "Wavelength [\\A]" ) );
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
yrange(1.e-10, 1); ylog;
xrange(21, 23);
hplot( x1, x2, y, 1 );

% Find the strongest lines by equivalent width
variable strongest = xstar_strong(10, db; wmin=21.0, wmax=23.0 );

% Print a table of the strongest lines
xstar_page_group( db, strongest; sort="ew" );

% Mark them on the current plot
variable lstyle = line_label_default_style();
lstyle.top_frac = 0.85;
xstar_plot_group( db, strongest, 3, lstyle );


%%----------------------------------------------------------------
%% Example 2: Multiple warmabs components at different redshifts
%% See Holczer et al. (2010) ApJ 708, 981 for inspiration
%% From multi_warmabs_tutorial.sl

% Absorber 1: Local (z=0) material
% Absorber 2: Fast outflow from MCG -6-30-15
% Inspiration : see Holczer et al. (2010) ApJ 708, 981
%
fit_fun("Powerlaw(1) * ( warmabs2(2) + warmabs2(3) )");
set_par("warmabs2(*).write_outfile", 1);
set_par("warmabs2(*).autoname_outfile", 1);

set_par( "warmabs2(2).column", -1 ); % Log10(1.e20/1.e21)
set_par( "warmabs2(2).rlogxi", -1.0 );
set_par( "warmabs2(2).vturb", 100.0 );
set_par( "warmabs2(2).Redshift", 0.0 );

set_par( "warmabs2(3).column", log10(8.1) );
set_par( "warmabs2(3).rlogxi", 3.8 );
set_par( "warmabs2(3).vturb", 500.0 );

% For sake of example, 
% I increased the redshift in comparison to paper
set_par( "warmabs2(3).Redshift", 0.1 ); 

% Evaluate the model
variable y2 = eval_fun(x1, x2);

% Load the files as a marged database
variable db_m = xstar_merge( ["warmabs_2.fits", "warmabs_3.fits"] );
variable z    = [ get_par("warmabs2(2).Redshift"), get_par("warmabs2(3).Redshift")];

% Find all lines within 18 - 24 Angs
yrange( 0.05, 0.2 );
xrange( 18, 24 );
hplot(x1, x2, y2, 1);

variable lines = xstar_strong( 50, db_m; wmin=18.0, wmax=24.0, redshift=z );
variable l1 = lines[ where(db_m.origin_file[lines] == 0) ];
variable l2 = lines[ where(db_m.origin_file[lines] == 1) ];

xstar_plot_group(db_m, l1, 2, lstyle, z[0]);
xstar_plot_group(db_m, l2, 3, lstyle, z[1]);

% There is a lot of substructure associated with an edge; this is not documented as lines
variable edge = where( xstar_wl(db_m, 18.0, 20.0; redshift=z) and db_m.type == "edge/rrc" );
xstar_page_group(db_m, edge);


% Find all lines within 6 - 10 Angs
yrange( 0.15, 0.25 );
xrange( 6, 10 );
hplot(x1, x2, y2, 1);

variable lines = xstar_strong( 5, db_m; wmin=6.0, wmax=10.0, redshift=z );
variable l1 = lines[ where(db_m.origin_file[lines] == 0) ];
variable l2 = lines[ where(db_m.origin_file[lines] == 1) ];

lstyle2 = line_label_default_style();
lstyle2.bottom_frac = 0.4;
lstyle2.top_frac = 0.6;
lstyle2.offset = 0.7;

xstar_plot_group(db_m, l1, 2, lstyle2, z[0]);
xstar_plot_group(db_m, l2, 3, lstyle2, z[1]);


