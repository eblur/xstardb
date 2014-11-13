%%%%
%% atomdb_tutorial.sl
%% 2014.09.23 : lia@space.mit.edu
%%
%% This tutorial will show you how to run a simple collisional plasma
%% model (APED), navigate the atomic database (AtomDB), and plot lines.
%%
%%%%

%% 0. Load the atomic database into the environment

plasma(aped);

%%----------------------------------------------------------------%%
%% 1. Create a single component plasma model.

%%    I will name this model "xapec" to differentiate it from the
%%    "apec" model provided by XSPEC.
create_aped_fun("xapec", default_plasma_state() );

%% The global variable "default_plasma_state" is a structure
%% containing essential model parameters.  These can always be changed
%% later, but this structure defines the default values. See Section
%% 7.5 of ISIS 1.0 manual.

fit_fun("xapec(1)"); % Set xapec to be the model function for this session.

set_par("xapec(1).temperature", 1.16e8); % 10 keV plasma in CIE
list_par; % List the parameters associated with the model

%% Since there is no data to fit in this tutorial, create a grid for
%% evaluating the model
variable x1, x2;
(x1, x2) = linear_grid(1.0, 40.0, 10000);
variable y = eval_fun(x1, x2);

%% Plot it
plot_bin_density; % Sets output to plot specific flux
xlabel( latex2pg( "Wavelength [\\A]" ) ) ;
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
ylog;
hplot(x1, x2, y, 1); % Section 7.6 of ISIS 1.0 manual

%%----------------------------------------------------------------%%
%% 2. Navigate the database (AtomDB)
%%
%% In general one can navigate the information from AtomDB without
%% setting or evaluating a model, but this tutorial will also
%% sdemonstrate how to use AtomDB to evaluate the model output, which
%% is useful when plotting data.

%% A. The "wl" function searches for transition in the specified range
%% (units:Angstroms)
%%
%% Note that it returns an array the length of the entire
%% database. The entries are '0' and '1', a boolean specifying whether
%% or not that line fits the search results. Use the "where" function
%% to get the index associated with that line.

variable line_indices = where( wl(18.0, 20.0) );

%% B. The "page_group" function neatly displays information from the
%% database. Show the first ten lines (no specific order).
page_group(line_indices[[0:9]]);

%% Note that many of the fluxes read 0. That's because the entire
%% database is being queried. See step D.

%% C. Use "line_info" function to return a structure containing database
%% entries for that line, including the flux values.
variable single_line = line_info( line_indices[0] );
print(single_line); % Prints structure contents

%% D. View information from lines with non-zero flux only.

%% I've created a function that systematically returns line fluxes for
%% every transition in the database
define line_fluxes()
{
    variable i, ll = length( wl(0,_Inf) );
    variable result = Float_Type [ll];
    for (i=0; i<ll; i++) result[i] = line_info(i).flux; ;
    return result;
}

%% This function is slow, so I'll store it (only have to run once)
variable model_fluxes = line_fluxes();
page_group( where( wl(18.0,20.0) and model_fluxes > 0.0 ) ); % 38 in total

%% E. The "el_ion" function retrieves lines specified from a list of
%% elements and/or ions.  The elements can be specified by atomic
%% number (ex: [14,26]) or using global variables corresponding to
%% periodic table designation (ex: [Si,Fe]).  The ionization state
%% corresponds to the roman numeral system used in astronomy (ex:
%% Fe-26 is He-like iron).

%% List all non-zero flux lines coming from He- and H-like iron
variable Fe_lines = where( el_ion(Fe, [26,27]) and model_fluxes > 0.0 );
page_group(Fe_lines);

%%----------------------------------------------------------------%%
%% 3. Plot line transitions within some range

xrange(19.0, 22.0);
hplot(x1, x2, y, 1);

%% A. The "brightest" function picks out the N brightest lines from an
%% input line list

variable bright_lines = brightest(5, where(wl(19,22)) );
page_group( bright_lines );

%% B. The "plot_group" function plots lines on the current plot
%%    Input order: line_indices, color_int, style, redshift

plot_group( bright_lines, 3 ); % Plots green lines

%% Note that if some lines are very close together, you will see only
%% one label.

%% C. You can play with line plotting style using the line style
%% structure.  Initialize it with "line_label_default_style"

variable style = line_label_default_style(); % Section 7.3 of ISIS 1.0 manual
print(style);

style.top_frac = 0.9;
style.bottom_frac = 0.7;
style.angle = 45.0;
style.offset = 0.05;

hplot(x1, x2, y, 1);
plot_group( [603604, 603679], 3 ); % Plots Fe lines with default style in green
plot_group( [35822, 35805, 35798], 2, style ); % Plots N lines with special style in red

%% TODO: Check out line_em



