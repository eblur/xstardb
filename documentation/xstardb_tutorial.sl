%%%%
%% wadb_tutorial.sl
%% 2014.09.24 : lia@space.mit.edu
%%
%% This tutorial will show you how to run a warmabs + photemis model,
%% available from XSTAR.  The new XSTAR models output a fits files
%% containing post-processed information about line and edge features.
%% This documents explains how to navigate and plot information from
%% the datasets.

%% O. Load the XSTAR database utilities
require("xstardb");

% An easy way to discover all of the wadb commands available:
apropos("xstar");

%%----------------------------------------------------------------%%
%% 1. Create a warmabs + photemis model

fit_fun( "Powerlaw(1) * warmabs2(1) + photemis2(123)" );

% Turn on writing of a fits file
set_par("warmabs2(1).write_outfile",  1 );
set_par("photemis2(123).write_outfile",  1);
set_par("*.autoname_outfile", 1); 
% All files will be subscripted according to numbered labels
% In this case: warmabs_1.fits and photemis_123.fits will be output

variable x1, x2;
(x1, x2) = linear_grid(1.0, 40.0, 10000);
variable y = eval_fun(x1, x2);
% XSTAR runs at this point, and fits files are output

%% Plot it
plot_bin_density; % Sets output to plot specific flux
xlabel( latex2pg( "Wavelength [\\A]" ) ) ;
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
ylog;
hplot(x1, x2, y, 1); % Section 7.6 of ISIS 1.0 manual


%%----------------------------------------------------------------%%
%% 2. Read and navigate results from XSTAR run

variable wa = rd_xstar_output("warmabs_1.fits");
variable pe = rd_xstar_output("photemis_123.fits");
% The result is a structure containing relevant info for each line and
% edge feature

% Print the structure to see what fields it contains, e.g.
print(wa);

%% A. The "xstar_wl" function searches for transitions in the
%% specified range (units:Angstroms). You also need to specify the
%% database on which to search.
%%
%% Note that it returns an array the length of the entire
%% database. The entries are '0' and '1', a boolean specifying whether
%% or not that line fits the search results. Use the "where" function
%% to get the index associated with that line.

variable WMIN = 28.0, WMAX = 33.0;

variable wa_features = where( xstar_wl(wa, WMIN, WMAX) );
variable pe_features = where( xstar_wl(pe, WMIN, WMAX) );

%% B. The "xstar_page_group" function neatly displays information from
%% the database.  Show the first ten lines (no specific order).

% The default is to sort by wavelength.
xstar_page_group(wa, wa_features[[0:9]]);

% To sort by other fields, e.g. equivalent width or luminosity
xstar_page_group(wa, wa_features[[0:9]]; sort="ew");
xstar_page_group(pe, pe_features[[0:9]]; sort="luminosity");

%% You can use boolean statements to narrow down on other parameters.
%% For example, I will find all the edges in the warmabs and photemis
%% model within a specified wavelength range.

variable wa_edges = where( xstar_wl(wa,WMIN,WMAX) and wa.type == "edge/rrc" );
xstar_page_group(wa, wa_edges);

variable pe_edges = where( xstar_wl(pe,WMIN,WMAX) and pe.type == "edge/rrc" );
xstar_page_group(pe, pe_edges);

% Note which values are non-zero

%% C. The "xstar_el_ion" function retrieves transitions specified from
%% a list of elements and/or ions.  The elements can be specified by
%% atomic number (ex: [14,26]) or using global variables corresponding
%% to periodic table designation (ex: [Si,Fe]).  The ionization state
%% corresponds to the roman numeral system used in astronomy (ex:
%% Fe-26 is He-like iron).

% List all the carbon transitions from the warmabs model
variable wa_C = where( xstar_wl(wa, WMIN, WMAX) and xstar_el_ion(wa, [C]) );
xstar_page_group(wa, wa_C);

% List all the photemis transitions from N-5 and N-6
variable pe_N = where( xstar_wl(pe, WMIN, WMAX) and xstar_el_ion(pe, N, [5,6]) );
xstar_page_group(pe, pe_N);

%% D. Use the "xstar_strong" function to retrieve line indices
%% associated with the largest equivalent width (in the case of a
%% warmabs model) or the largest luminosity (in the case of a photemis
%% model).  The function is "smart" and determines which parameter to
%% use based on the fits file header.
%%
%% Input: xstar_strong( N_features, db_struct[; qualifiers]);
%% Qualifier options:
%%    wmin, wmax, elem (integer), ion (integer) 
%%    type: "line" | "edge" | "rrc" | "any" (default)
%%    field: any string that corresponds to a field name in db_struct
%%    (defaults: "luminosity" if photemis model, "ew" if warmabs model, 
%%     "tau0grid" if type=="edge", "luminosity" if type=="rrc")

% Find the 5 strongest absorbers
variable wa_strongest = xstar_strong(5, wa; wmin=WMIN, wmax=WMAX);
xstar_page_group(wa, wa_strongest; sort="ew");

% Use the "type" qualifier to pick different transition types,
% e.g. radiative recombination edges instead of lines.  The default is
% to look at any transition.
variable pe_strongest_edge = xstar_strong(5, pe; wmin=WMIN, wmax=WMAX, type="rrc");
xstar_page_group(pe, pe_strongest_edge; sort="luminosity");


%%----------------------------------------------------------------%%
%% 3. Plot line transitions within some range

xrange(WMIN, WMAX);
yrange(1.e-8,0.1);
hplot(x1, x2, y, 1);

%% The "xstar_plot_group" function plots lines on the current plot
%% -- Input order: db_struct, line_indices, color_int, style, redshift
%%
%% You can play with the line plotting style using the line style
%% structure.  Initialize it with "line_label_default_style"

% Plot the strongest warmabs lines from above, in green
variable wa_style = line_label_default_style();
wa_style.top_frac = 0.9;
wa_style.bottom_frac = 0.8;
wa_style.angle = 0.0;

xstar_plot_group(wa, wa_strongest, 3, wa_style);

% Plot the strongest absorption edge from below, in orange
variable pe_strongest_edge = xstar_strong(1, pe; wmin=WMIN, wmax=WMAX, type="rrc");
xstar_page_group(pe, pe_strongest_edge; sort="luminosity");

variable edge_style = line_label_default_style();
edge_style.top_frac = 0.5;
edge_style.bottom_frac = 0.8; 
edge_style.angle=0.0;

xstar_plot_group(pe, pe_strongest_edge, 8, edge_style);
