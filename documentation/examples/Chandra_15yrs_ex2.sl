%%
%% Chandra_15yrs_ex2.sl : One of three examples from our poster at the
%%                        15 yeras of Chandra symposium
%%
%% Created 2014.11.11   : lia@space.mit.edu
%%

require("xstardb");

%%----------------------------------------------------------------
%% Example 2: Multiple warmabs components at different redshifts
%% See Holczer et al. (2010) ApJ 708, 981 for inspiration
%% This is taken from multi_warmabs_tutorial.sl

% Absorber 1: Local (z=0) material
% Absorber 2: Fast outflow from MCG -6-30-15
% Inspiration : see Holczer et al. (2010) ApJ 708, 981
%
fit_fun("Powerlaw(1) * ( warmabs2(1) + warmabs2(2) )");
set_par("warmabs2(*).write_outfile", 1);
set_par("warmabs2(*).autoname_outfile", 1);

set_par( "warmabs2(1).column", -1 ); % Log10(1.e20/1.e21)
set_par( "warmabs2(1).rlogxi", -1.0 );
set_par( "warmabs2(1).vturb", 100.0 );
set_par( "warmabs2(1).Redshift", 0.0 );

set_par( "warmabs2(2).column", log10(8.1) );
set_par( "warmabs2(2).rlogxi", 3.8 );
set_par( "warmabs2(2).vturb", 500.0 );

% Redshift should be z_obj + v_outflow/c
variable z_fast = 0.007749 - 1900.e5 / Const_c;
set_par( "warmabs2(1).Redshift", 0.0 ); 
set_par( "warmabs2(2).Redshift", z_fast );

% Evaluate the model
variable x1, x2;
(x1, x2) = linear_grid( 1.0, 40.0, 10000 );
variable y2 = eval_fun( x1, x2 );

% Load the files as a marged database
variable db_m = xstar_merge( ["warmabs_1.fits", "warmabs_2.fits"] );
variable z    = [ get_par("warmabs2(1).Redshift"), get_par("warmabs2(2).Redshift") ];

% Find strong lines within 18 - 24 Angs
plot_bin_density;
xlabel( latex2pg( "Wavelength [\\A]" ) );
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
yrange( 0.05, 0.2 ); ylog;
xrange( 18, 24 );
hplot( x1, x2, y2, 1 );

variable lines = xstar_strong( 50, db_m; wmin=18.0, wmax=24.0, redshift=z );
variable l1 = lines[ where(db_m.origin_file[lines] == 0) ];
variable l2 = lines[ where(db_m.origin_file[lines] == 1) ];

variable lstyle = line_label_default_style();
lstyle.top_frac = 0.82;

xstar_plot_group(db_m, l1, 2, lstyle, z[0]);
xstar_plot_group(db_m, l2, 3, lstyle, z[1]);

%% Note that warmabs doesn't keep track of "inner shell edges";
%% The substructure around 19 - 20 Angstroms is associated with the
%% O V edge around 18.5 Angs
%%
%% This is not a good example to show, as the missing strong features
%% will probably bring up more questions than answers.  Look for a
%% cleaner example.


% Find strongest lines within 8 - 10 Angs
yrange( 0.15, 0.22 );
xrange( 8, 10 );
hplot(x1, x2, y2, 1);

variable lines = xstar_strong( 4, db_m; wmin=8.0, wmax=10.0, redshift=z );
variable l1 = lines[ where(db_m.origin_file[lines] == 0) ];
variable l2 = lines[ where(db_m.origin_file[lines] == 1) ];

xstar_page_group( db_m, lines; redshift=z );

xstar_plot_group( db_m, l1, 2, lstyle, z[0] );
xstar_plot_group( db_m, l2, 3, lstyle, z[1] );



