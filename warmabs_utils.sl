% -*- mode: SLang; mode: fold -*-
%; Date: 2014.10.06
%; Directory:  /vex/d1/lia/wadb_repo.git
%; File:       warmabs_utils.sl
%; Author:     David P. Huenemoerder <dph@space.mit.edu>, Lia Corrales <lia@space.mit.edu>
%; Orig. version: 2015.08.15 - See ~/dph/h3/Analysis/ADP_2010_atomic_data/packages/warmabs_db-0.3/
%;========================================
%

% 0.3.4 lia changed most function names to use xstar_ prefix,
%           xstar_el_ion behavior updated to emulate el_ion
%           xstar_plot_group behavior updated to emulate plot_group
%           xstar_page_group updated to handle merged lists

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
define xstar_set_outfile( f )
{
    WARMABS_OUTFILE = f ;
    putenv( "WARMABS_OUTFILE=$f"$ ) ; 
}

define xstar_get_outfile()
{
    return( getenv("WARMABS_OUTFILE") );
}

define warmabs_unset_outfile()
{
   xstar_set_outfile("");
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
	 xstar_set_outfile( sprintf( "%s_%d.fits",
	               warmabs_fname, Isis_Active_Function_Id ) ) ;
    }

    % otherwise, use whatever action is imposed - either the 
    % default warmabs<idx>.fits, or the user-specified environment variable. 

    % else % use default action, which is "warmabs<idx>.fits"
    % {
    % 	xstar_set_outfile("");
    % }

    variable y = eval_fun2( warmabs_handle, lo, hi, warmabs_pars ) ;
    % xstar_set_outfile("");  % disable env name
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
private variable Elements = Assoc_Type[];
private variable Roman = Assoc_Type[];
private variable Roman_Numerals;
private variable Upcase_Elements;

private define init_elems()
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

private define parse_ion_string (s)
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

private define make_transition_name_string (Z, q, upper_level, lower_level, type)
{
    return sprintf ("%s %s %s - %s [%s]",
                     Upcase_Elements[ Z-1 ], Roman_Numerals[ q-1 ],
                     lower_level, upper_level, type);
}


% 2014.07.14 dph; add a field, "model", and read the header keyword, "MODEL", 
% which specifies which type was run (e.g., warmabs, photemis, hotemis...).

private define load_warmabs_file (file)
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Start of joint dph, lia code
%

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
define rd_xstar_output()
{
    if( _NARGS == 0 or _NARGS > 1)
    {
	message("USAGE:  db = rd_xstar_output( filename )");
	return;
    }

    variable fname = ();
    variable result = load_warmabs_file( fname );
    result = struct_combine( result, "filename" );
    result.filename = fname;
    return( result );
}


% Manage redshift values 
private define form_z_array( s, redshift )
{
    variable z = Double_Type[length(s.Z)];

    if ( struct_field_exists(s, "origin_file") )
    {
	variable ii;
	foreach ii ([0:length(s.filename)-1])
	{
	    z[ where(s.origin_file == ii) ] = redshift[ii];
	}
    }
    else
    {
	z += redshift[0];
    }

    return z;
}

%
% boolean array for transitions within a wavelength range
%
define xstar_wl( s, wlo, whi )
{
    variable rs0 = 0.0;
    if (struct_field_exists(s,"filename")) rs0 = Double_Type[length(s.filename)];
    % ^This conditional is necessary in case s is a grid.mdb structure
    
    variable rs = qualifier("redshift", rs0 );
    variable z  = form_z_array( s, rs );

    return s.wavelength * (1+z) > wlo and s.wavelength * (1+z) <= whi;
}


%
% boolean array for transitions from a particular element and/or ion
%
define xstar_el_ion()
{
    % s is database structure
    % el_list is array of atomic numbers
    % ion_list is array of ions

    % example:
    % l = xstar_el_ion( s, Ne, [9,10] );

    variable s, el_list;
    variable ion_list = Integer_Type[0];

    % load arguments
    switch( _NARGS )
    { case 2: ( s, el_list ) = (); }
    { case 3: ( s, el_list, ion_list ) = (); }
    {
        message("Wrong number of arguments.");
        message("USAGE: flags = xstar_el_ion( db_struct, atomic_number[,  ion] )" );
        return -1;
    }

    % Perform comparisons
    variable result = ismember( s.Z, el_list );

    if ( length(ion_list) > 0 )
    {
	result = result and ismember( s.q, ion_list );
    }

    return result;
}

%
% boolean array containing transitions based on lower and/or upper level index
%
% USAGE: index = xstar_trans( s, el, ion[, lower[, upper]] );
%
define xstar_trans()
{
    variable s, el, ion;
    variable lower = Integer_Type[0];
    variable upper = Integer_Type[0];

    % load arguments
    switch(_NARGS)
    { case 3   : (s, el, ion) = (); }
    { case 4   : (s, el, ion, lower) = (); }
    { case 5   : (s, el, ion, lower, upper) = (); }
    {
	message("Wrong number of arguments.");
	message("USAGE: flags = xstar_trans( db_struct, atomic_number, ion[, ind_lower[, ind_upper]] );" );
	return -1;
    }

    variable result = xstar_el_ion( s, el, ion );

    if ( length(lower) > 0 )
    {
	result = result and ismember(s.ind_lo, lower);
    }

    if ( length(upper) > 0 )
    {
	result = result and ismember(s.ind_up, upper);
    }


    return result;
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% prototype a "strong" function for warmabs_db variables.
%
% for warmabs, "strong" could apply to tau0grid, or ew
%
% for photemis, to luminosity.
%
% default to warmabs_db if warmabs, luminosity if photabs, or tau0 if type="edge"; 
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
%             type = "line" | "edge" | "rrc" 
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

    if ( qualifier_exists( "wmin" ) ) wmin =  qualifier( "wmin" );
    if ( qualifier_exists( "wmax" ) ) wmax =  qualifier( "wmax" );

    if ( qualifier_exists( "field") ) field = qualifier( "field" );
    variable v = get_struct_field( s, field ) ;

    variable lw = NULL ;
    variable l  = NULL ;
    variable r  = NULL ;

    % Pick out features from element, ion, and wavelength range of interest
    % Manage wavelengths and redshift
    variable rs = qualifier( "redshift", Double_Type[length(s.filename)] );
    variable z  = form_z_array( s, rs );

    lw =  s.wavelength * (1.0+z) > wmin and 
          s.wavelength * (1.0+z) <= wmax  ;

    if ( qualifier_exists( "elem" ) ) lw = lw and s.Z == qualifier( "elem" );
    if ( qualifier_exists( "ion"  ) ) lw = lw and s.q  == qualifier( "ion" );
    if ( qualifier_exists( "limit" ) ) lw = lw and v >= qualifier( "limit" );

    lw = where( lw  and  ltype ) ;
    if ( length( lw ) == 0 )  return( NULL );   % NO MATCH

    % Sort features by field of interest (contained in v)
    l  = array_sort(  v[ lw ] ) ;
    n  = min( [length( lw ), n ] );
    r  = lw[ l[ [-n:] ] ]; % grab the tail end of the sorted array

    % put in ascending wavelength order
    r = r[ array_sort( s.wavelength[r] ) ] ; 

    return( r ); 
}

private variable warmabs_db_model_type =
  ["", "hotabs", "hotemis", "warmabs", "photemis", "multabs", "windabs", "scatemis" ];


%
% s is the structure from reading output FITS files;
% l is an index array (filter)
% qualifier: Redshift - for altering the wavelengths of the lines
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
    "#%7s",
    " %9s",
    " %8s",
    " %10s",
    " %10s",
    " %3s",
    " %3s",
    " %10s",
    " %10s",
    " %12s",
    " %10s",
    " %24s"
    ] ; 

    variable dfmt = [
    "%8d",
    " %3s",
    " %5s",
    " %8.4f",
    " %10.3e",
    " %10.3e",
    " %3.0f",
    " %3.0f",
    " %10.3e",
    " %10.3e",
    " %12.3e",
    " %10s",
    " %12s -", 
    " %12s"
    ] ; 

    variable fields = [
    "transition", 
    "Z",
    "q",
    "wavelength",
    "a_ij",
    "f_ij",
    "g_lo",
    "g_up",
    "tau0grid",
    "ew",
    "luminosity",
    "type",
    "lower_level", 
    "upper_level"
    ];


    % Handle any redshift issues
    variable rs = qualifier("redshift", Double_Type[length(s.filename)] );
    variable z  = form_z_array( s, rs );

    % If it is a merged database, there will be an additional "origin file" column
    if (struct_field_exists(s, "origin_file"))
    {
	hdr = [hdr, "origin"];
	hfmt = [hfmt, " %24s\n"];
	dfmt = [dfmt, " %12s\n"];
	fields = [fields, "origin"];
    }
    else
    {
	hfmt[-1] += "\n";
	dfmt[-1] += "\n";
    }

    % output printed to screen or file 
    variable fp = qualifier( "file", stdout ) ;
    if ( typeof(fp) == String_Type ) fp = fopen( fp, "w" );

    % print the header
    () = array_map( Integer_Type, &fprintf, fp, hfmt, hdr ) ;

    % Sort by field (descending order)
    % Special cases: sort wavelength by ascending order
    %                tau0 should refer to tau0grid field
    %                none prints in the order provided by user
    variable sorted_l;
    variable fsort = qualifier( "sort", "wavelength" );
    switch( fsort )
    { case "none":       sorted_l = l; }
    { case "wavelength": sorted_l = l[ array_sort(s.wavelength[l]*(1.0+z[l])) ]; }
    { case "tau0":       sorted_l = reverse( l[ array_sort(s.tau0grid[l]) ] );}
    { sorted_l = reverse( l[ array_sort( get_struct_field(s, fsort)[l] ) ] ); }

    % print the data piece by piece
    variable i, j, k, n = length( l );
    for (i=0; i<n; i++)
    {
	k = sorted_l[i];
	for (j=0; j<length(fields); j++)
	{
	    switch( fields[j] )
	    { case "wavelength": () = fprintf(fp, dfmt[j], s.wavelength[k]*(1.0+z[k])); }
	    { case "Z": () = fprintf(fp, dfmt[j], Upcase_Elements[ s.Z[k]-1 ]); }
	    { case "q": () = fprintf(fp, dfmt[j], Roman_Numerals[ s.q[k]-1 ]); }
	    { case "origin": () = fprintf(fp, dfmt[j], s.filename[s.origin_file[k]]); }
	    { () = fprintf( fp, dfmt[j], get_struct_field(s, fields[j])[k] ); }
	}
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
    variable labels;
    if ( style.label_type == 1 )
    {
	labels = s.transition_name[l];
    }
    else
    {
	labels = Upcase_Elements[ s.Z[l]-1 ] + " " + Roman_Numerals[ s.q[l]-1 ];
    }

    plot_linelist(wl, labels, ci, style, z);
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2014.10.06 - Dealing with multiple XSTAR runs
% Updates from lia, using examples/warmabs_vs_xi_test.sl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Merge two XSTAR models into a single database structure
%
% USAGE: xstar_merge(["file1.fits","file2.fits"])
% RETURNS: A database structure with an extra column, db_fname
%
define xstar_merge( file_list )
{
    variable fname, db_list = Struct_Type[0];
    foreach fname (file_list) db_list = [db_list, rd_xstar_output(fname)];

    variable fields = get_struct_field_names(db_list[0]);
    variable result = @db_list[0];

    % add and initialize the "origin_file" column
    variable dblen = length(db_list[0].transition);
    result = struct_combine( result, "origin_file" );
    result.origin_file = Integer_Type[dblen];

    variable i, ff, temp1, temp2, ogfile;
    for (i=1; i<length(db_list); i++)
    {
	% append all information to end of result
	foreach ff (fields)
	{
	    temp1 = get_struct_field( result, ff );
	    temp2 = get_struct_field( db_list[i], ff );
	    set_struct_field( result, ff, [temp1, temp2] );
	}

	% create an array of strings containing new filename, append to result
	dblen  = length(db_list[i].transition);
	ogfile = Integer_Type[dblen] + i;
	result.origin_file = [result.origin_file, ogfile];
    }

    return result;
}


%-----------------------------------------------------------------------
% Run a set of models

private variable x1, x2;
(x1, x2) = linear_grid( 1.0, 40.0, 8192 );

variable _default_binning = struct{ bin_lo, bin_hi };
set_struct_fields( _default_binning, x1, x2 );

variable _default_model_info = struct{ mname, pname, min, max, step, bins };

% USAGE: xstar_run_model_grid( info, rootdir[; nstart]);

% info = struct{ bins, mname, pname, min, max, step }
% info.bins = struct{ bin_lo, bin_hi }
% rootdir   = string describing the root directory to dump all the files into

define xstar_run_model_grid( info, rootdir )
{
    % starting numbering index for model output
    variable n0 = qualifier( "nstart", 0 );
    if ( typeof(n0) != Integer_Type ) { print("nstart must be an integer"); return; }
    print("The starting index is");
    print(n0);

    %variable g = struct{ bin_lo, bin_hi, value };
    %(g.bin_lo, g.bin_hi) = linear_grid( 1.0, 40.0, 8192 );

    variable sfun  = info.mname;
    variable pname = info.pname;
    variable pgrid = [ info.min : info.max+info.step : info.step ] ;
    variable n = length( pgrid ); 

    variable t = get_fit_fun ;   % to save the current model

    fit_fun( "$sfun($n0)"$ );
    set_par( "$sfun($n0).write_outfile"$, 1 );

    variable fpar = get_par( "*" );
    variable pidx  = where( array_struct_field( get_params , "name" ) == "$sfun($n0).$pname"$)[0];

    fit_fun( t );  % restore the saved model

    variable i, fref = fitfun_handle( sfun );

    variable r = struct{ bin_lo, bin_hi, value };
    r.bin_lo   = @info.bins.bin_lo ;
    r.bin_hi   = @info.bins.bin_hi ;
    r.value    = Array_Type[ n ] ; 

    % Use eval_fun2() to evaluate each model.  This means that the
    % autoname_outfile feature will not work because the
    % Isis_Active_Function_Id is not defined (or is always 0).  Hence,
    % we will use the unwrapped models and set the output filename via
    % the env.

    for ( i=1; i<=n; i++ )
    {
	xstar_set_outfile( sprintf( rootdir + "%s_%d.fits", sfun, n0+i ) );
	fpar[ pidx ] = pgrid[ i-1 ] ;
	message( "Running  $sfun vs $pname ... $i"$ );
	() = printf("debug: pgrid[%d]=%8.2f\n", i-1, fpar[pidx] );
	r.value[i-1] = eval_fun2( fref, r.bin_lo, r.bin_hi, fpar );
	title( "$i"$ ); ylog; limits; hplot( r.bin_lo, r.bin_hi, r.value[i-1] );
    }
    warmabs_unset_outfile;

    return( r ) ; 
}


%-----------------------------------------------------------------------
% Load a set of models into a model grid structure

% mdb : master db for grid structure
% db  : db to merge with master db (mdb)
% ii  : indices pointing to unique array values
private define merge_master_db( mdb, db, ii )
{
    variable field_list = get_struct_field_names( mdb );
    variable ff, temp1, temp2;
    foreach ff (field_list)
    {
	temp1 = get_struct_field( mdb, ff );
	temp2 = get_struct_field( db, ff );
	set_struct_field( mdb, ff, [temp1, temp2][ii] );
    }
}

private define add_unique_id( g )
{
    variable db, temp, ii, k;
    for (k=0; k<length(g.db); k++)
    {
	temp    = g.db[k].ind_ion * 10000000LL + 
	          g.db[k].ind_lo * 10000LL + 
	          g.db[k].ind_up;
	g.db[k] = struct_combine( g.db[k], "uid" );
	g.db[k].uid = @temp;

	g.uids = [g.uids, @temp];
	ii     = unique( g.uids );  % sorts while identifying unique indices

	% Append database info onto master database,
	% keeping only unique values
	g.uids = g.uids[ii];
	merge_master_db( g.mdb, g.db[k], ii );
    }
}

% after reading a table, get a value from the params substructure:
% e.g., this is where the model rlogxi, column, vturb are.
% "interesting" parameters in xspec models are rlogxi, column, "vturb".
% These map to xstar output parameters, "rlogxi", "column", "vturbi", 
% note that column is in units of cm^-2
%
private define xstar_get_table_param( t, s )
{
    variable l = where( t.params.parameter == s )[0] ; 
    return( t.params.value[ l ] );
}

% collect a parameter of interest into an array
%
define xstar_get_grid_par( g, p )
{
    variable r = array_map( Double_Type, &xstar_get_table_param, g.db, p );
    return( r );
}


define xstar_load_tables( fnames )
{
    variable result = struct{ db, mdb, uids, uid_flags };
    result.db = array_map( Struct_Type, &rd_xstar_output, fnames );

    result.uids  = Int_Type[0];
    result.mdb   = struct{ type, ion, wavelength, 
                           lower_level, upper_level, Z, q, 
                           a_ij, f_ij, g_lo, g_up,
                           ind_ion, ind_up, ind_lo,
                           transition_name };
    set_struct_fields( result.mdb, String_Type[0], String_Type[0], Double_Type[0], 
                       String_Type[0], String_Type[0], Integer_Type[0], Integer_Type[0],
                       Float_Type[0], Float_Type[0], Float_Type[0], Float_Type[0],
                       Integer_Type[0], Integer_Type[0], Integer_Type[0], String_Type[0] );

    % Deal with assigning unique ids and flagging
    add_unique_id( result );

    result.uid_flags = Array_Type[length(result.db)];
    variable i;
    for (i=0; i<length(result.db); i++)
    {
	result.uid_flags[i] = ismember( result.uids, result.db[i].uid );
    }

    return result;
}


% g: a grid structure
% l: indices for g.uids array
%
define xstar_page_grid( g, l )
{
    
    variable hdr =    [
    "uid",     % unique LLong integer for line
    "ion",     % elem ion
    "lambda",  % wavelength
    "A[s^-1]", % a_ij
    "f",       % f_ij
    "gl",      % g_lo
    "gu",      % g_up
    "type",    % type
    "label"    % lower_level - upper_level
    ] ;
    
    variable hfmt = [
    "#%11s",
    " %9s",
    " %8s",
    " %10s",
    " %10s",
    " %3s",
    " %3s",
    " %10s",
    " %24s\n"
    ] ; 

    variable dfmt = [
    "%12lld",
    " %3s",
    " %5s",
    " %8.4f",
    " %10.3e",
    " %10.3e",
    " %3.0f",
    " %3.0f",
    " %10s",
    " %12s -",
    " %12s\n"
    ] ; 
    
    variable fields = [
    "uid",
    "Z",
    "q",
    "wavelength",
    "a_ij",
    "f_ij",
    "g_lo",
    "g_up",
    "type",
    "lower_level",
    "upper_level"
    ];

    % Sort by field (descending order)
    % Special cases: sort wavelength by ascending order
    %                sort uid in ascending order
    %                none prints in the order provided by user
    variable sorted_l;
    variable fsort = qualifier( "sort", "wavelength" );
    switch( fsort )
    { case "wavelength": sorted_l = l[ array_sort(g.mdb.wavelength[l]) ]; }
    { case "uid":        sorted_l = l[ array_sort(g.uids[l]) ]; }
    { case "none":       sorted_l = l; }
    { sorted_l = reverse( l[ array_sort( get_struct_field(g.mdb, fsort)[l] ) ] ); }

    % set up output area
    variable fp = qualifier( "file", stdout ) ;
    if ( typeof(fp) == String_Type ) fp = fopen( fp, "w" );

    % print header
    () = array_map( Integer_Type, &fprintf, fp, hfmt, hdr ) ;

    % print everything
    variable i, j, k, n = length( l );
    for (i=0; i<n; i++)
    {
	k = sorted_l[ i ] ; 
	for (j=0; j<length(fields); j++)
	{
	    switch( fields[j] )
	    { case "uid": () = fprintf( fp, dfmt[j], g.uids[k] ); }
	    { case "Z": () = fprintf( fp, dfmt[j], Upcase_Elements[g.mdb.Z[k]-1] ); }
	    { case "q": () = fprintf( fp, dfmt[j], Roman_Numerals[g.mdb.q[k]-1] ); }
	    { () = fprintf( fp, dfmt[j], get_struct_field(g.mdb, fields[j])[k] ); }
	}
    }
}


%%% Utilities for navigating the grid structure

define xstar_unpack_uid( uid )
{
    variable ion, lo, up ;
    ion = uid mod 1000 ;
    up  = uid / 1000 mod 10000 ;
    lo  = uid / 10000000 ;
    return( ion, lo, up );
}



%% Returns lists of booleans, for use with where function
% USE: find_line(wa_grid, ll)
% RETURNS: An array of character arrays containing boolean flags for use with where function
%
private define xstar_find_line( grid, ll )
{
    variable uid = grid.uids[ll][0];
    variable i, result = Array_Type[length(grid.db)];
    for( i=0; i<length(grid.db); i++ )
    {
	result[i] = grid.db[i].uid == uid;
    }
    return result;
}


%% Get the property of a given line, using the "field" entry
% USE: xstar_line_prop( wa_grid, ll, "ew" )
% RETURNS: An Double_Type array containing the value of the field of interest.
% NOTE: Will break if used on a field that contains a string
%
define xstar_line_prop( grid, ll, field )
{
    variable i, fl_list;
    variable temp, result = Double_Type[length(grid.db)];

    fl_list = xstar_find_line( grid, ll );
    
    for( i=0; i<length(grid.db); i++ )
    {
	temp = where(fl_list[i]);
	if( length(temp) != 0) result[i] = get_struct_field( grid.db[i], field )[temp][0];
    }
    
    return result;
}


%% Get line ratios accross the entire grid
% USE: xstar_line_ratios( grid, l1, l2, field )
% RETURNS: A Double_Type array contianing the ratio l2/l1 over the
%          field of interest
% INPUT: Both l1 and l2 may be lists of indices.  In this case the
% line properties will be summed (presumably because they are blended
% lines).  This will be done without regard to field type or ion
% species.
%
define xstar_line_ratios( grid, l1, l2, field )
{
    variable val1 = 0.0;
    variable val2 = 0.0;

    variable l;
    foreach l (l1) val1 += xstar_line_prop( grid, l, field );
    foreach l (l2) val2 += xstar_line_prop( grid, l, field );

    return val2 / val1;
}






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

provide( "warmabs_utils" );
message( "\nwarmabs_utils $warmabs_db_version_string loaded\n"$);



