%%%%
%% bugtest_missing_10.28.sl
%% 2014.10.28 : lia@space.mit.edu
%%
%% I found lines missing from the database in
%% ../documentation/tutorials/multi_warmabs_tutorial.sl
%%
%% Duplicate here for further study.  Which of the two component
%% models is the culprit?

require("xstardb");
variable x1, x2;
(x1, x2) = linear_grid( 1.0, 40.0, 8192 ); 

% Absorber 1 model
fit_fun("warmabs2(1)");
set_par( "warmabs2(1).column", -1 ); % Log10(1.e20/1.e21) ??
set_par( "warmabs2(1).rlogxi", -1.0 ); % Guess
set_par( "warmabs2(1).vturb", 100.0 );
set_par( "warmabs2(1).Redshift", 0.0 );

set_par("warmabs2(*).write_outfile", 1);
set_par("warmabs2(*).autoname_outfile", 1);
variable y1 = eval_fun(x1, x2);

%%---
variable db = rd_xstar_output("warmabs_1.fits");

variable AMIN = 19.5;
variable AMAX = 22.0;

plot_bin_density;
xlabel( latex2pg( "Wavelength [\\A]" ) ) ;
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
ylog;
xrange(AMIN, AMAX);
hplot(x1, x2, y1, 1);

%% Identify all transitions in this region
variable l = where(xstar_wl(db, AMIN, AMAX));
xstar_page_group(db, l);

variable lstyle = line_label_default_style();
lstyle.top_frac = 0.5;
lstyle.bottom_frac = 0.75;
lstyle.offset = 0.5;
xstar_plot_group(db, l, 2, lstyle);

%%---
%% Let's look at second absorber just for fun

% Absorber 2 model
fit_fun("warmabs2(2)");

set_par( "warmabs2(2).column", log10(8.1) );
set_par( "warmabs2(2).rlogxi", 3.8 );
set_par( "warmabs2(2).vturb", 500.0 );
set_par( "warmabs2(2).Redshift", 0.1 ); 

set_par("warmabs2(*).write_outfile", 1);
set_par("warmabs2(*).autoname_outfile", 1);

variable y2 = eval_fun(x1, x2);

%% Plot over a larger range, that includes the wavelengths in question
hplot(x1, x2, y2, 1);

%%--

variable db2 = rd_xstar_output("warmabs_2.fits");

variable l2 = where( xstar_wl(db2, AMIN, AMAX; redshift=get_par("warmabs2(2).Redshift")) );
xstar_page_group(db2, l2; sort="ew");

xstar_plot_group( db2, l2, 3, lstyle, get_par("warmabs2(2).Redshift") );


%%-- 
%% 10.29 : Turn off everything except Oxygen.  Dave said he tried
%% every element in turn and Oxygen appeared associated with that 20
%% Angstrom line.
%%
%% It might be part of an edge, so look for edge structure

fit_fun("warmabs2(3)");

set_par( "warmabs2(3).column", -1 ); % Log10(1.e20/1.e21) ??
set_par( "warmabs2(3).rlogxi", -1.0 ); % Guess
set_par( "warmabs2(3).vturb", 100.0 );
set_par( "warmabs2(3).Redshift", 0.0 );

set_par( [3:27], 0.0 );
set_par( "warmabs2(3).Oabund", 1.0 );

set_par("warmabs2(*).write_outfile", 1);
set_par("warmabs2(*).autoname_outfile", 1);
variable y3 = eval_fun(x1, x2);

hplot(x1, x2, y3, 1); 

%%--

variable db_o = rd_xstar_output("warmabs_3.fits");
variable o_trans = where( xstar_wl(db_o, AMIN, AMAX) );
xstar_plot_group(db_o, o_trans, 2, lstyle);

variable o_edges = where( xstar_wl(db_o, 1, 40) and db_o.type == "edge/rrc" );
xstar_page_group(db_o, o_edges);

%%--
%% Now try nothing but nitrogen

fit_fun("warmabs2(4)");

set_par( "warmabs2(4).column", -1 ); % Log10(1.e20/1.e21) ??
set_par( "warmabs2(4).rlogxi", -1.0 ); % Guess
set_par( "warmabs2(4).vturb", 100.0 );
set_par( "warmabs2(4).Redshift", 0.0 );

set_par( [3:27], 0.0 );
set_par( "warmabs2(4).Nabund", 1.0 );

set_par("warmabs2(*).write_outfile", 1);
set_par("warmabs2(*).autoname_outfile", 1);
variable y4 = eval_fun(x1, x2);

hplot(x1, x2, y4, 1); %nothing

%%--
%% Look at the bigger picture

xrange(1.0,40.0);
hplot(x1, x2, y4, 1); % N only
ohplot(x1, x2, y3, 2); % O only


%%--
%% Write the contents of the O-only spectrum to an ascii table

writecol("O-only.text", x1, x2, y3);

%% Make an example plot

xrange(16, 22);
hplot(x1, x2, y3, 1);
xstar_plot_group( db_o, where(xstar_wl(db_o, 16, 22)), 2, lstyle );

