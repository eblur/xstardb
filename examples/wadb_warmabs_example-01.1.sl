% 2014.05.08 dph
%
% test warmabs_db prototype functions on warmabs model output
%
% 2014.08.07 lia - updated to v1.1 for testing on vex


require( "warmabs_db");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% misc. plotting utilities:

stdpltsetup; resize(20,0.5);

variable x1, x2 ;
(x1, x2) = linear_grid( 1.0, 40.0, 16384 ) ; 

% Define a model;  warmabs is an xspec local model:

fit_fun( "warmabs2( 1 ) * Powerlaw(1)" );

% auto-define output file:
set_par( "warmabs2(1).autoname_outfile", 1 ); %<--- warmabs2 has the autoname_outfile param
set_par( "warmabs2(1).write_outfile", 1 );

variable wa_col = 0.5, wa_xi  = 2.5, wa_vt  = 250 ; 

set_par( "warmabs2(1).column", wa_col );
set_par( "warmabs2(1).rlogxi", wa_xi );
set_par( "warmabs2(1).vturb",  wa_vt  );

set_par( "Powerlaw(1).alpha", -2 );
set_par( "Powerlaw(1).norm", 15 );

save_par( "warmabs2-001.par");

% evaluate the model on the grid and load the resulting table:
%
variable y1 = eval_fun( x1, x2 );
variable c1 = rd_warmabs_output( "warmabs_1.fits" );

% check the warmabs_wl function (lia)
%
variable ll = warmabs_wl(c1, 13, 15);
% It is an array of '0' characters!

% Look at the spectrum:

define do_plt_01()
{
    plot_bin_density;
    xlabel( latex2pg( "Wavelength [\\A]" ) ) ; 
    ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
    xrange; xlin;  yrange; ylin; 
    cp1;pst; hplot( x1, x2, y1, 1 ) ; 
}

do_plt_01;

variable s = "a warmabs model spectrum:" ; 
message(s); pltid( s; size=1.4, color=4 );
plot_pause; 

% get list of strongest features in a wavelength range:

define do_plt_02()
{
    variable l = xstar_strong( 50, c1; wmin = 13, wmax = 15 );
    xrange( 13, 15 ) ; yrange( 0 ) ; 
    cp1;pst; hplot( x1, x2, y1, 1 ) ; 
    xstar_plot_group( c1, l );
}

do_plt_02;
s = "Strongest features in 13--15A region:";
message(s); pltid(s ; size=1.4, color=4);
xstar_page_group( c1, xstar_strong( 50, c1; wmin = 13, wmax = 15 ) );
plot_pause; 


% find Ne features
%

define do_plt_03()
{
    variable lne = xstar_strong( 5, c1; elem = Ne );
    xrange(10,14);
    cp1;pst; hplot( x1, x2, y1,1 ) ; 
    xstar_plot_group( c1, lne );
}

do_plt_03;
s = "Mark strong Ne features:";
message(s); pltid(s ; size=1.4, color=4);
plot_pause; 

define do_plt_04()
{
    variable l  = xstar_strong( 20, c1; wmin=18, wmax=23);
    variable lo = xstar_strong( 10, c1; elem=O, wmin=18, wmax=23 );
    xrange(18, 23);
    cp1;pst; hplot( x1, x2, y1,1 ) ; 
    xstar_plot_group( c1, l );
    xstar_plot_group( c1, lo );
}

do_plt_04;
s="Strong O features in 18--21A range:";
message(s); pltid(s ; size=1.4, color=4);
plot_pause; 


% look for edges:
define do_plt_05()
{
    variable l = xstar_strong( 10, c1; wmin=1, wmax=40, type="edge", field="tau0");
    xrange(3, 26);
    cp1;pst; hplot( x1, x2, y1,1 ) ; 
    xstar_plot_group( c1, l );
}

do_plt_05;
s="Look for edge features:";
message(s); pltid(s ; size=1.4, color=4);
plot_pause;

xstar_page_group( c1, xstar_strong( 10, c1; wmin=1, wmax=40, type="edge", field="tau0") );

define do_plt_06()
{
    variable l = xstar_strong( 5, c1; wmin=13, wmax=16, type="edge", field="tau0");
    xrange( 13, 15 );
    cp1;pst; hplot( x1, x2, y1,1 ) ; 
    xstar_plot_group(c1, l);
}

do_plt_06;
s="Strongest edge features in 13--16A region:";
message(s); pltid(s ; size=1.4, color=4);
plot_pause;
xstar_page_group( c1, xstar_strong( 5, c1; wmin=13, wmax=16, type="edge", field="tau0") );

%------------------------------
% 2014.08.22 - lia - Try a new plotting function (plot_linelist or plot_group)
%
variable l = xstar_strong( 5, c1; wmin=13, wmax=16, type="edge", field="tau0");
xrange( 13, 15 );
cp1;pst; hplot( x1, x2, y1,1 ) ; 

% test the line style
variable test_ls = line_label_default_style();
test_ls.bottom_frac = 0.0;

xstar_plot_group(c1, l);
xstar_plot_group(c1, l, 3);
xstar_plot_group(c1, l, 4, test_ls);
xstar_plot_group(c1, l, 2, test_ls, 0.005);
xstar_plot_group(c1, l, 4, test_ls, 0.05, 500); % Returns an error message, as it should

%------------------------------

variable pid; 

message( "Create plots and feature tables:");

pid = open_plot("wa_example_01.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_01;
close_plot(pid); window(1);

pid = open_plot("wa_example_02.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_02;
close_plot(pid); window(1);

pid = open_plot("wa_example_03.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_03;
close_plot(pid); window(1);

pid = open_plot("wa_example_04.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_04;
close_plot(pid); window(1);

pid = open_plot("wa_example_05.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_05;
close_plot(pid); window(1);

pid = open_plot("wa_example_06.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_06;
close_plot(pid); window(1);

xstar_page_group( c1, xstar_strong(20, c1; wmin=18, wmax=23) );
xstar_page_group( c1, xstar_strong(20, c1; wmin=18, wmax=23); file="wa_list_01.tbl" );
xstar_page_group( c1, xstar_strong(5, c1; wmin=5, wmax=10, type="edge", field="tau0"); file="wa_edge_list_01.tbl" );
