% -*- mode: SLang; mode: fold -*-
%; Time-stamp: <2014-08-15 13:05:04 dph>
%; Directory:  ~dph/h3/Analysis/ADP_2010_atomic_data/packages/warmabs_db-0.3/
%; File:       warmabs_utils-0.2.sl
%; Author:     David P. Huenemoerder <dph@space.mit.edu>
%; Orig. version: 2015.05.06
%;========================================
%

% 0.3.3 dph added units to the warmabs2 wrappers - copied over from 
%           the xstar models (even though the units of column is [cm^-2] 
%           when it is really dex([cm^-2])).


% 0.3.2 - revise reading of warmabs output - generalize function, 
%         and save model name in the structure.

% 0.3.1 - test "_fit" on warmabs2 function, to debug namespace issues...
%         --- yes, need _fit on model definitions (misunderstood the
%             isis help when using a function reference)

% version:  0.3.0
%   2014.05.08  - change el/ion handling, using j.houck code

%%%
%          
% purpose: utilities for working with the warmabs model output files.
%          
% NOTE: this wrapper should work with any of the xspec local model
% warmabs class function (warmabs, photemis, hotabs, hotemis, multabs,
% windabs)
%          

% The warmabs models have 2 parameters and one env variable to control
% the way it can write output FITS files containing atomic data:
%
%  parameter:  write_outfile [0|1]
%              outfile_idx   [1:10000]
%  env:        WARMABS_OUTFILE
% 
%  If write_outfile = 1, the output file will be written.
%  If WARMABS_OUTFILE is set, then it's value will be the output
%    filename.
%  If WARMABS_OUTFILE is not set, then outfile_idx is used as an index
%  on the rootname, "warmabs", as "./warmabs<nnnn>.fits" (where <nnnn>
%  represents outfile_idx, 0-padded).
%
% Note there is a problem with use of WARMABS_OUTFILE and multiple
% instances of models with write_outfile=1, e.g., "photemis(1) +
% photemis(2)":  the second instance will overwrite the file from the
% former.  Here one could use the built-in name ("warmabs") and the
% index method.  This can be mitigated by using the warmabs wrapper
% functions, warmabs2, photemis2, etc, which introduce an auto-naming
% feature and control parameter (see below).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
private variable _version = [0,3,2];

variable warmabs_db_version = sum( _version * [ 10000, 100, 1 ] ) ; 
variable warmabs_db_version_string =
            sprintf("%d.%d.%d", _version[0], _version[1], _version[2] ) ; 


private variable WARMABS_ROOT            = "/tmp/watmp" ; 
private variable WARMABS_OUTFILE_DEFAULT = "${WARMABS_ROOT}.fits"$ ; 
private variable WARMABS_OUTFILE         = "${WARMABS_ROOT}.fits"$ ; 

% Use f="" to disable use of WARMABS_OUTFILE:
%
define warmabs_set_outfile( f )
{
    WARMABS_OUTFILE = f ;
    putenv( "WARMABS_OUTFILE=$f"$ ) ; 
}

define warmabs_get_outfile()
{
    return( getenv("WARMABS_OUTFILE") );
}

define warmabs_unset_outfile()
{
   warmabs_set_outfile("");
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Re-define the warmabs model suite so that we can include a parameter
% to specify automatic naming of the output file.  The name will be
% the model name ("warmabs", "photemis", etc) and the model instance.
% E.g., if the fit fun is "warmabs(123)" and the write_outfile and
% autoname_outfile parameters are set to 1, then the outfile will be
% warmabs_123.fits. 
%          
% We do this by caching the default parameter sets (for names and
% defaults), and then define a new model using those parameters (and
% default), and add one parameter.  The models are evaluated with
% eval_fun2(). 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize the warmabs etc parameter sets, and cache them:
%
private variable warmabs_models =
   [ "warmabs", "photemis", "hotabs", "hotemis", "multabs", "windabs", "scatemis"]; 

private variable warmabs_mdl_par_names = Assoc_Type[ Array_Type ];
private variable warmabs_mdl_par       = Assoc_Type[ Array_Type ];

% need a check for currently missing i/o parameters; 
% It looks like they are in the upated version, to-be-installed [2014.05.07]
private define check_for_warmabs_io_par( s )
{
    variable p = array_struct_field( get_params( "$s(9999).*"$), "name" );
    variable f = length( where( p == "$s(9999).write_outfile"$ ) );
    return( f );
}

private define init_warmabs_params()
{
    variable s, i  ;
    foreach s ( warmabs_models )
    {
	fit_fun( "$s(9999)"$ );
	if (check_for_warmabs_io_par(s) ) set_par( "$s(9999).write_outfile"$, 0, 1 );
	warmabs_mdl_par[ s ]       = get_params ; 
	warmabs_mdl_par_names[ s ] = array_struct_field( get_params, "name" ) ;
	variable units = array_struct_field( get_params, "units" );
	units[where(strlen(units)==0)] = " ";
	for (i=0; i<length( warmabs_mdl_par_names[ s ] ); i++ )
	{
	    warmabs_mdl_par_names[s][i] = strchop( warmabs_mdl_par_names[s][i], '.', 0)[1];
	}
	warmabs_mdl_par_names[s] += "[" + units + "]" ; 
    }
}

init_warmabs_params;


% Re-define the models so they have a new parameter to control
% auto-naming output files:

% All the warmabs models get evaluated by this function; 
% The name is passed as an argument.
% The env variable for the outfile is set as <model_name>_<model_instance>.fits
%
private define _warmabs2( warmabs_fname, lo, hi, par )
{
    variable warmabs_handle = fitfun_handle( warmabs_fname );
    variable warmabs_pars   =  par[ [:-2] ] ;   % original params
    variable autoname       = int( par[-1] ) ;  % new param

    if ( autoname ) % set the outfile name in the environment:
    {
	 warmabs_set_outfile( sprintf( "%s_%d.fits",
	               warmabs_fname, Isis_Active_Function_Id ) ) ;
    }

    % otherwise, use whatever action is imposed - either the 
    % default warmabs<idx>.fits, or the user-specified environment variable. 

    % else % use default action, which is "warmabs<idx>.fits"
    % {
    % 	warmabs_set_outfile("");
    % }

    variable y = eval_fun2( warmabs_handle, lo, hi, warmabs_pars ) ;
    % warmabs_set_outfile("");  % disable env name
    return( y );
}

% Define user-level model names by appending a "2" to the warmabs
% intrinsic names:

define warmabs2_fit( lo, hi, par )
{
    return( _warmabs2( _function_name[[:-6]], lo, hi, par ) ) ;
}
define photemis2_fit( lo, hi, par )
{
    return( _warmabs2( _function_name[[:-6]], lo, hi, par ) ); 
}
define hotabs2_fit( lo, hi, par )
{
    return( _warmabs2( _function_name[[:-6]], lo, hi, par ) ) ;
}
define hotemis2_fit( lo, hi, par )
{
    return( _warmabs2( _function_name[[:-6]], lo, hi, par ) ) ;
}
define multabs2_fit( lo, hi, par )
{
    return( _warmabs2( _function_name[[:-6]], lo, hi, par ) ) ;
}
define windabs2_fit( lo, hi, par )
{
    return( _warmabs2( _function_name[[:-6]], lo, hi, par ) ) ;
}
define scatemis2_fit( lo, hi, par )
{
    return( _warmabs2( _function_name[[:-6]], lo, hi, par ) ) ;
}

private variable fptr =
  [&warmabs2_fit, &photemis2_fit, &hotabs2_fit, &hotemis2_fit, &multabs2_fit, &windabs2_fit, &scatemis2_fit ] ; 

private variable fnorms = { NULL, 0, NULL, 0, NULL, NULL, 0 };

private define register_funs()
{
    variable i;  
    for( i=0; i<length(fptr); i++ )
    {
	variable f = warmabs_models[ i ] ;
	variable p = [ warmabs_mdl_par_names[ f ], "autoname_outfile"] ; 
	add_slang_function( "${f}2"$, p, fnorms[i] );
    }
}
register_funs;

% this is what register_funs does:
#iffalse
add_slang_function( "warmabs2",  &warmabs2_fit,  [ warmabs_mdl_par_names[ "warmabs" ], "autoname_outfile" ] );
add_slang_function( "photemis2", &photemis2_fit, [ warmabs_mdl_par_names[ "photemis"], "autoname_outfile" ], [0] );
add_slang_function( "hotabs2",   &hotabs2_fit,   [ warmabs_mdl_par_names[ "hotabs"  ], "autoname_outfile" ] );
add_slang_function( "hotemis2",  &hotemis2_fit,  [ warmabs_mdl_par_names[ "hotemis" ], "autoname_outfile" ], [0] );
add_slang_function( "multabs2",  &multabs2_fit,  [ warmabs_mdl_par_names[ "multabs" ], "autoname_outfile" ] );
add_slang_function( "windabs2",  &windabs2_fit,  [ warmabs_mdl_par_names[ "windabs" ], "autoname_outfile" ] );
add_slang_function( "scatemis2", &scatemis2_fit, [ warmabs_mdl_par_names[ "scatemis"], "autoname_outfile" ], [0] );
#endif

%%% parameter defaults, using those saved from the basic warmabs models:
%
private variable spar = struct{ value, min, max, hard_min, hard_max, step, relstep, freeze} ;
private variable s_autoname = struct{ value=1, min=0, max=1, hard_min=0, hard_max=1, step=0.01, relstep=1.e-4, freeze=1} ;

private define _warmabs2_defaults( s, i )
{
    variable p = warmabs_mdl_par[ s ];
    if (i == length( p )) return( s_autoname );

    variable k ; 
    foreach k ( get_struct_field_names( spar ) )
    {
	set_struct_field( spar, k, get_struct_field( p[i], k ) );
    }
    return( spar );
}

define warmabs2_defaults( i )
{
    return( _warmabs2_defaults( _function_name[[:-11]], i ) );
}
define photemis2_defaults( i )
{
    return( _warmabs2_defaults( _function_name[[:-11]], i ) );
}
define hotabs2_defaults( i )
{
    return( _warmabs2_defaults( _function_name[[:-11]], i ) );
}
define hotemis2_defaults( i )
{
    return( _warmabs2_defaults( _function_name[[:-11]], i ) );
}
define multabs2_defaults( i )
{
    return( _warmabs2_defaults( _function_name[[:-11]], i ) );
}
define windabs2_defaults( i )
{
    return( _warmabs2_defaults( _function_name[[:-11]], i ) );
}

private variable k ; 
foreach k ( warmabs_models )
   set_param_default_hook( "${k}2"$, "${k}2_defaults"$ );

% (end of model re-definition)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Utilities for working with the FITS tables
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% From J.Houck:
%
%private
variable Elements = Assoc_Type[];
%private 
variable Roman = Assoc_Type[];
%private 
variable Roman_Numerals;
%private 
variable Upcase_Elements;

%private 
define init_elems()
{
    Upcase_Elements =
    ["H" , "He", "Li", "Be", "B" , "C" , "N" , "O" , "F" , "Ne",
    "Na", "Mg", "Al", "Si", "P" , "S" , "Cl", "Ar", "K" , "Ca",
    "Sc", "Ti", "V" , "Cr", "Mn", "Fe", "Co", "Ni", "Cu", "Zn",
    "Ga", "Ge", "As", "Se", "Br", "Kr"];

    Roman_Numerals =
    ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
    "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX",
    "XXI", "XXII", "XXIII", "XXIV", "XXV", "XXVI", "XXVII", "XXVIII", "XXIX", "XXX",
    "XXXI", "XXXII", "XXXIII", "XXXIV", "XXXV", "XXXVI", "XXXVII"];

    variable names        = Upcase_Elements;
    variable num_elements = length( names );

    variable i;
    _for i (0, num_elements-1, 1)
    {
        Elements[ names[ i ] ]            = i + 1 ;
        Elements[ strlow( names[ i ] ) ]  = i + 1 ;
        Roman[ Roman_Numerals[ i ] ]      = i + 1 ;
    }
}
init_elems();
%

%private 
define parse_ion_string (s)
{
    variable t = strtok (s, "_");
    if (length(t) != 2)
    return NULL;

    variable  name = t[0],
              ion_roman = strup( t[1] );

    variable i = Elements[ name ];
%    variable Name = Upcase_Elements[i-1];

    variable Z = i,
             q = Roman[ ion_roman ] ;

    return Z, q;
}

%private 
define make_transition_name_string (Z, q, upper_level, lower_level, type)
{
    return sprintf ("%s %s %s %s [%s]",
                     Upcase_Elements[ Z-1 ], Roman_Numerals[ q-1 ],
                     upper_level, lower_level, type);
}


% 2014.07.14 dph; add a field, "model", and read the header keyword, "MODEL", 
% which specifies which type was run (e.g., warmabs, photemis, hotemis...).


define load_warmabs_file (file)
{
    variable db = fits_read_table ("${file}[XSTAR_LINES]"$);

    variable nbad = howmany(db.wavelength <= 0);
    if (nbad != 0)
    {
        vmessage ("%s: WARNING %d/%d wavelengths are <= 0",
	file, nbad, length(db.wavelength));
    }

    db = struct_combine (db, "model_name", "params", "Z", "q", "transition_name");

    db.params = fits_read_table ("${file}[PARAMETERS]"$);

    (db.Z, db.q) = array_map (Int_Type, Int_Type, &parse_ion_string, db.ion);
    db.transition_name =
       array_map (String_Type, &make_transition_name_string,
                     db.Z, db.q, db.upper_level, db.lower_level, db.type);

    % dph mod:
    db.model_name = fits_read_key( "${file}[XSTAR_LINES]"$, "MODEL" );
    variable l = array_sort( db.wavelength ) ;
    struct_filter( db, l );

    return db;
}
%
% (end of j.houck code)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% get indices for an element, ion pair:
%
define warmabs_db_elion( s, el, ion )
{
    return( s.elem == el and s.ion == ion ) ;
}

private variable T_HOTABS   = 1, 
		 T_HOTEMIS  = 2,
		 T_WARMABS  = 3,
		 T_PHOTEMIS = 4,
		 T_MULTABS  = 5,
		 T_WINDABS  = 6,
		 T_SCATEMIS = 7; 

private variable model_map = Assoc_Type[ Integer_Type ] ;
model_map[ "hotabs"   ] = T_HOTABS ; 
model_map[ "hotemis"  ] = T_HOTEMIS  ; 
model_map[ "warmabs"  ] = T_WARMABS  ; 
model_map[ "photemis" ] = T_PHOTEMIS ; 
model_map[ "multabs"  ] = T_MULTABS  ; 
model_map[ "windabs"  ] = T_WINDABS  ; 
model_map[ "scatemis" ] = T_SCATEMIS ; 


% Read the FITS table; re-structure by adding element,ion fields, and
% sorting on wavelength:
%

define rd_xstar_output( s )
{
    variable t = load_warmabs_file( s );
    return( t ) ;
}



%
% find indices within a wavelength range:
%
define xstar_wl( s, wlo, whi )
{
    variable lw =  s.wavelength > wlo and s.wavelength <= whi;

    return lw;
}


%
% find indices from a particular element or ion
%
define xstar_el_ion()
{
    variable s, el_list, ion_list="None";
    variable el, el_result = 0;
    variable ion, ion_result = 0;

    switch(_NARGS)
    { _NARGS <= 1: message("ERROR: Requires at least two arguments, database structure and element"); return; }

    { case 2: el_list = (); s = (); 
    foreach el (el_list) el_result = el_result or (s.Z == el);; 
    return el_result; }

    { case 3: ion_list = (); el_list = (); s = (); 
    foreach el (el_list) el_result = el_result or (s.Z == el);; 
    foreach ion (ion_list) ion_result = ion_result or (s.q == ion);;
    return el_result and ion_result; }

    { _NARGS > 3: message("ERROR: Too many arguments, see help page"); return; 
}

}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% prototype a "strong" function for warmabs_db variables.
%
% for warmabs, "strong" could apply to tau0grid, tau02ewo
%
% for photemis, to luminosity.
%
% default to warmabs_db if warmabs, luminosity if photabs; 
% use a "field = " qualifier for any other.
%
% s is structure from  read of warmabs output FITS table
%      (which adds element, ion fields to the structure)
%
% n is number of strong features to return
%
% qualifiers: field = name for other fields of c (such as luminosity, tau0grid, tau02ewo)
%             emis         for strongest emission line equivalent widths (<0)
%             wmin = value minimum wavelength
%             wmax = value maximum wavelength
%             elem = Z     element atomic number
%             ion  = n     ion state ( 1 => neutral )
%             type = "line" | edge" | "rrc" 
%
define xstar_strong( n, s )
{
    % n = number of strongest features
    % s = structure returned by reading FITS table

    variable field, emis ; 

    %% Read from structure, not global variable

    switch( s.model_name )    % use model type to guess defaults:
    {
	case T_HOTABS or case T_WARMABS:  
	field = "ew" ;  % equivalent width
	emis = 0 ; 
    }
    {
	case T_HOTEMIS or case T_PHOTEMIS:  
	field = "luminosity" ;  % line luminosity;
	emis  = 1 ; 
    }
    {
	field = "ew" ;  % wild guess
	emis = 0 ; 
    }

    variable ftype = strlow( qualifier( "type", "any" ) );

    variable LINE_FEATURE_TYPE = "line" ;
    variable EDGE_FEATURE_TYPE = "edge/rrc" ; 

    variable ltype ;
    switch( ftype )
    {
	case "line":
	ltype = (s.type == LINE_FEATURE_TYPE);
    }
    {
	% Strong absorption edges should filter on tau0grid
	case "edge":
	ltype = (s.type == EDGE_FEATURE_TYPE);
	field = "tau0grid";
    }
    {
	% Radiative recombination edges should filter on luminosity
	case "rrc":
	ltype = (s.type == EDGE_FEATURE_TYPE);
	field = "luminosity";
    }
    {
	case "any":
	ltype = (s.type == LINE_FEATURE_TYPE or s.type == EDGE_FEATURE_TYPE);
    }
    {
	message("%% type of $ftype unknown; using any"$);
	ltype = (s.type == LINE_FEATURE_TYPE or s.type == EDGE_FEATURE_TYPE);
    }

    variable wmin = min( s.wavelength ); 
    variable wmax = max( s.wavelength ); 

    if ( qualifier_exists( "emis" ) ) emis =  1 ;
    if ( qualifier_exists( "wmin" ) ) wmin =  qualifier( "wmin" ) ;
    if ( qualifier_exists( "wmax" ) ) wmax =  qualifier( "wmax" ) ;

    if ( qualifier_exists( "field") ) field = qualifier( "field" );
    variable v = get_struct_field( s, field ) ;

    variable lw = NULL ;
    variable l  = NULL ;
    variable r  = NULL ;

    % Pick out features from element, ion, and wavelength range of interest
    lw =  s.wavelength > wmin and s.wavelength <= wmax  ;

    if ( qualifier_exists( "elem" ) ) lw = lw and s.Z == qualifier( "elem" ) ;
    if ( qualifier_exists( "ion"  ) ) lw = lw and s.q  == qualifier( "ion" ) ;

    lw = where( lw  and  ltype ) ;
    if ( length( lw ) == 0 )  return( NULL );   % NO MATCH

    % Sort features by field of interest (contained in v)
    l  = array_sort(  v[ lw ] ) ;
    n  = min( [length( lw ), n ] );
    r  = lw[ l[ [-n:] ] ]; % grab the tail end of the sorted array
    
    % EXCEPT in the case of emission features, where ew is a negative value
    if ( emis and field == "ew" )  % want smallest (most negative)
    {
	r = lw[ l[ [0:n-1] ] ] ;
    }

    % put in ascending wavelength order
    r = r[ array_sort( s.wavelength[r] ) ] ; 

    return( r ); 
}

private variable warmabs_db_model_type =
  ["", "hotabs", "hotemis", "warmabs", "photemis", "multabs", "windabs", "scatemis" ];


%
% s is the structure from reading output FITS files;
% l is an index array (filter)
%
define xstar_page_group( s, l )
{
    variable hdr =    [
    "id",      % transition
    "ion",     % elem ion
    "lambda",  % wavelength
    "A[s^-1]", % a_ij
    "f",       % f_ij
    "gl",      % g_lo
    "gu",      % g_up
    "tau_0",   % tau0grid
    "W(A)",    % ew
    "L[10^38 cgs]",  % luminosity
    "type",    % type
    "label"    % lower_level - upper_level
    ] ;
    
    variable hfmt = [
    "# %7s",
    " %8s",
    " %8s",
    " %10s",
    " %10s",
    " %3s",
    " %3s",
    " %10s",
    " %10s",
    " %12s",
    " %10s",
    " %S\n"
    ] ; 

    variable dfmt = [
    "%8d",
    "%3s %5s",
    "%8.3f",
    "%10.3e",
    "%10.3e",
    "%3d",
    "%3d",
    "%10.3e",
    "%10.3e",
    "%12.3e",
    "%10s",
    "%12s - %12s\n"
    ] ; 
    
    variable fp = qualifier( "file", stdout ) ;
    if ( typeof(fp) == String_Type ) fp = fopen( fp, "w" );

    () = array_map( Integer_Type, &fprintf, fp, hfmt, hdr ) ;

    %% Sort by field (descending order, except lambda)
    variable sorted_l;
    variable fsort = qualifier( "sort", "wavelength" );
    switch( fsort )
    { case "wavelength": sorted_l = l[ array_sort(s.wavelength[l]) ]; }
    { case "ew":         sorted_l = reverse( l[ array_sort(s.ew[l]) ] ); }
    { case "luminosity": sorted_l = reverse( l[ array_sort(s.luminosity[l]) ] ); }
    { case "tau0":       sorted_l = reverse( l[ array_sort(s.tau0grid[l]) ] );}
    { case "none":       sorted_l = l; }

    variable i, n = length( l );

    for (i=0; i<n; i++)
    {
	%variable k = l[ i ] ; 
	variable k = sorted_l[ i ] ; 
	() = fprintf( fp, strjoin( dfmt, " "),
	     s.transition[k],
	     Upcase_Elements[ s.Z[k]-1 ], Roman_Numerals[ s.q[k]-1 ],
	     s.wavelength[k],
	     s.a_ij[k],
	     s.f_ij[k],
	     int(s.g_lo[k]),
	     int(s.g_up[k]),
	     s.tau0grid[k],
	     s.ew[k],
	     s.luminosity[k],
	     s.type[k],
	     s.lower_level[k], s.upper_level[k]
	);
    }
}



% Usage: xstar_plot_group( xstardb_file, line_list[, color_index[, line_style]] );
%% NOTE: Does not support long labels (style.label_type=1) and will ignore
define xstar_plot_group()
{
    variable s, l, ci=2, style = line_label_default_style(), z = 0.0;

    switch(_NARGS)
    { _NARGS <= 1: message("ERROR: Requires two arguments"); return; }
    { case 2: l = (); s = (); }
    { case 3: ci = (); l = (); s = (); }
    { case 4: style = (); ci = (); l = (); s = (); }
    { case 5: z = (); style = (); ci = (); l = (); s = (); }
    { _NARGS > 5: message("ERROR: Too many arguments"); return; }

    variable wl = s.wavelength[l];
    variable labels = Upcase_Elements[ s.Z[l]-1 ] + " " + Roman_Numerals[ s.q[l]-1 ];

    plot_linelist(wl, labels, ci, style, z);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

%%%------------------------------------------------------------------
%%%%%% extras, for plotting


define setvp( xmin, xmax, ymin, ymax )
{
    set_outer_viewport( struct {xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax } );
}


define stdpltsetup()
{
    set_frame_line_width(3);
    setvp( 0.12, 0.98, 0.12, 0.9);
    charsize( 1.4 ) ;
    set_line_width( 5 ) ;
    _pgscf(2);  % nicer pgplot fonts.
}

define pltid( )  % ( x, y, s )
{
    variable x = 0.01, y = 0.01, s = time ;
    
    variable s_usage =
`USAGE: pltid( [[x,y], s] ; options);
Write a string, s, to identify the current plot; default is time.
EXAMPLE:  pltid( time  + " user@somewhere" );
Qualifiers: color, angle, size, justify, width` ;

    switch ( _NARGS )
    {
	case 0:
    }
    {
	case 1:  s = () ;
    }
    {
	case 2: (x,y) = () ;
    }
    {
	case 3: ( x, y, s ) = () ;
    }
    {
	message( s_usage ) ; 
	return ; 
    }

    if ( qualifier_exists( "help" ) )
    {
	message( s_usage ) ; 
	return ; 
    }
    
    variable p = get_plot_options;
    xlin; ylin; 
    _pgswin( 0, 1, 0, 1 ) ;
    _pgsvp( 0, 1, 0, 1);

    variable c = qualifier( "color",   1 ) ;
    variable a = qualifier( "angle",   0 ) ;
    variable b = qualifier( "size",    1 ) ;
    variable j = qualifier( "justify", 0 ) ;
    variable w = qualifier( "width",   1 ) ;

    set_line_width( w ) ;     charsize( b ) ;     color( c ) ;

    xylabel( x, y, s, a, j );

    set_plot_options( p ) ; 
}
%-----------------------------------------------------------------------

define cp1() { connect_points(1);}
define cp0() { connect_points(0);}
define pst() { pointstyle(-1);}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

provide( "warmabs_utils" );
message( "\nwarmabs_utils $warmabs_db_version_string loaded\n"$);
