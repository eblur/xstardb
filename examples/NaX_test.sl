
%% 2014.10.17 : NaX_test.sl
%% lia@space.mit.edu
%%
%% Run a photemis model with some large ionization parameter, set all
%% abundances to zero except Na and Ne, and look for He-like ion
%% triplets.
%% 
%% We want to understand what's going on with the strange duplicate
%% lines Na X (transition # 11515 and 11519)

require("warmabs_db");

%%%--- Set up and run the model ---%%%

variable x1, x2;
(x1, x2) = linear_grid( 1.0, 30.0, 50000 );

fit_fun("photemis2(11)");
set_par("photemis2(11).write_outfile", 1);
set_par("photemis2(11).autoname_outfile", 1);

% Turn up ionization
set_par("photemis2(11).rlogxi", 1.5);
% Set all abundances to 0, except for elements we want to test
set_par([3:27], 0.0);
set_par("photemis2(11).Naabund", 5.0);
set_par("photemis2(11).Neabund", 5.0);
set_par("photemis2(11).Oabund", 5.0);

list_par;

variable y = eval_fun(x1, x2);

% Plot it
plot_bin_density;
xlabel( latex2pg( "Wavelength [\\A]" ) ) ; 
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
ylog;
hplot(x1,x2,y,1);

%%%--- Load the resulting database ---%%%

variable db = rd_xstar_output("photemis_11.fits");

variable NaX_lines = where( xstar_el_ion(db, Na, 10) and db.type == "line" );
xstar_page_group(db, NaX_lines);

xrange(8.0, 12.0);
hplot(x1, x2, y, 1);
xstar_plot_group(db, NaX_lines);


%%%--- Find the Na lines in the photemis grid computed by Dave ---%%%

variable f = glob( "/vex/d1/lia/xstar_test/photemis_10*.fits" );
f = f[ array_sort(f) ];

variable pe_grid = xstar_load_tables(f);

variable NaX_glines = where( xstar_el_ion(pe_grid.mdb, Na, 10) and pe_grid.mdb.type == "line" );

xstar_page_grid( pe_grid,  NaX_glines );

%% what about warmabs?
variable f2 = glob( "/vex/d1/lia/xstar_test/warmabs_10*.fits" );
f2 = f2[ array_sort(f2) ];

variable wa_grid = xstar_load_tables(f);

variable NaX_glines2 = where( xstar_el_ion(wa_grid.mdb, Na, 10) and wa_grid.mdb.type == "line" );

xstar_page_grid( wa_grid, NaX_glines2 );

%% I always get the same four transitions, and no 1s1.2s1.3S or 1s1.2p1.3P transitions 



%%%--- 2014.10.20 : Look at triplet for more common elements, just to check ---%%%

variable ne_ix_lines = where( xstar_el_ion(db, Ne, 9) and db.type == "line" );
xstar_page_group( db, ne_ix_lines );

%% Triplet is there!
%% Plot it.

xrange(13.3, 13.8);
hplot(x1, x2, y, 1);

variable ne_ix_triplet = where( xstar_el_ion(db, Ne, 9) and xstar_wl(db, 13.0, 14.0) );
xstar_page_group( db, ne_ix_triplet );
%% I found a reference to line ratios in helium-like ion triplet
%% These are very close to line positions in Porquet+ (2001) A&A 376, 1113

xstar_plot_group( db, ne_ix_triplet, 2 );

%% compare to AtomDB

plasma(aped);
variable test_ne_ix = where( trans(Ne, 9, [2:7], 1) );
page_group(test_ne_ix);


%% Now look at the OVII triplet

variable o_vii_lines = where( xstar_el_ion(db, O, 7) and db.type == "line" );
xstar_page_group( db, o_vii_lines );

xrange(21.5, 22.5);
hplot(x1, x2, y, 1);

variable o_vii_triplet = where( xstar_el_ion(db, O, 7) and xstar_wl(db, 21.5, 22.5) );
xstar_page_group( db, o_vii_triplet );

xstar_plot_group( db, o_vii_triplet );

variable test_o_vii = where( trans(O, 7, [2:10], 1 ) );
page_group(test_o_vii);


%% What does AtomDB have to say about Na X?

variable test_na_x = where( trans(Na, 10, [2:10], 1 ) );
page_group(test_na_x);

%% Not much in common with the information in xstarlines

