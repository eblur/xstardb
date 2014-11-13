%
% 2014.11.13 lia - Reworked for public use
% 2014.01.10 dph
%
% setup the environment:

% local default path; change these as per your installation:
%
private variable local_lmoddir_linux32 = "/nfs/cxc/a2/opt/packages/xspec_lmodels/heasoft_6.16_32bit" ; 
private variable local_lmoddir_linux64 = "/nfs/cxc/a2/opt/packages/xspec_lmodels/heasoft_6.16_WARMABS_22DEV_OCT02_2014_64bit"; 
%/nfs/cxc/a2/opt/packages/xspec_lmodels/heasoft_6.16_64bit" ; 

private variable lmoddir      = NULL ;
private variable warmabs_data = lmoddir ;
private variable warmabs_pops = "pops.fits" ; 

define warmabs_print_setup()
{
    message("");
    message("%% LMODDIR = "      + getenv( "LMODDIR" ) );
    message("%% WARMABS_DATA = " + getenv( "WARMABS_DATA" ) );
    message("%% WARMABS_POP = "  + getenv( "WARMABS_POP" ) ) ;
    message("");
}

define get_local_defaults()
{
    message( "Checking env for local architecture-based paths...");

    switch ( getenv("CSR_CARCH" ) )
    {
	case "linux":
	lmoddir = local_lmoddir_linux32 ; 
    }
    {
	case "linux-x86_64":
	lmoddir = local_lmoddir_linux64 ; 
    }
    {
	message( "%% Unknown architecture; setup incomplete.");
    }

    warmabs_data = lmoddir ;
    warmabs_pops = "pops.fits" ;
}


% the env might be set, so just read it.
% 2014.11.13 - if it's not set, use get_local_defaults
%
define get_current_env()
{
    if ( getenv("LMODDIR") == NULL )
    {
	message("Environment variable LMODDIR is not set, switching to xstardb_setup defaults");
	get_local_defaults();
	return;
    }

    lmoddir      = getenv( "LMODDIR" ) ; 
    warmabs_data = getenv( "WARMABS_DATA" )  ; 
    warmabs_pops = getenv( "WARMABS_POP" ) ; 

    if ( warmabs_pops == NULL ) warmabs_pops = "pops.fits" ; 
}


define put_to_env()
{
    putenv ( "LMODDIR=$lmoddir"$ ) ;
    putenv ( "WARMABS_DATA=${warmabs_data}"$ ) ;
    putenv ( "WARMABS_POP=${warmabs_pops}"$ ) ;
}


define load_help_text()
{
    variable hf = path_concat(path_dirname (__FILE__), "xstardb_help.txt");
    add_help_file(hf);
}


define xstardb_setup()
{
    if ( qualifier_exists( "guess" ) )
    {
	get_local_defaults();
    }

    if ( qualifier_exists( "use_current" ) )
    {
	get_current_env() ;
    }

    lmoddir      = qualifier( "lmoddir",      lmoddir );
    warmabs_data = qualifier( "warmabs_data", lmoddir ) ;
    warmabs_pops = qualifier( "warmabs_pops", warmabs_pops ) ;

    put_to_env; 
    warmabs_print_setup;
    load_help_text;

    if ( qualifier_exists( "help" ) )
    {
	message( "%% USAGE: xstardb_setup( ; qualifiers );" );
	message(" %% " );
	message( "%%   qualifiers:" );
	message(" %% " );
	message(" %%      guess:          	Use a built-in default path");
	message(" %%      use_current:    	Use the current env settings");
	message(" %% " );
	message(" %%      lmoddir      = path: 	Specify a path explicitly");
	message(" %%      warmabs_data = path:  Specify a path explicitly [default: lmoddir]" ) ;
	message(" %%      warmabs_pops = path:  Specify a path explicitly [default: pops.fits]" ) ;
	message(" %% " );
	message(" %%  Setup up the warmabs env variables required by xspec/warmabs models.");
	message(" %% " );
	message(" %% EXAMPLE: xstardb_setup( ; guess );" );
	message(" %%          xstardb_print_setup()" ) ;
    }
}

provide( "xstardb_setup" );
