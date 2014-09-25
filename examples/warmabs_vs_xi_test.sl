% 2014.08.18 dph

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#iffalse

Generate a run of models vs rlogxi for warmabs and photemis to

 a - check for uniqueness of the line id ("transition" column in the output file);
 b - to experiment with collation of all the tables.

 We would like to be able to do database operations on the whole set
 of output files, e.g., to have  strength (e.g., equivalent width or
 luminosity) vs log(xi), or vs column.

 Note that the output file also contains the model parameters in an
 extension ( EXTNAME = 'PARAMETERS' ).

#endif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

require( "warmabs_db" );

% model, param, min, max, step
%
private variable _model_info = struct{ mname, pname, min, max, step };

variable warmabs_inf = @_model_info ;
set_struct_fields( warmabs_inf, "warmabs", "rlogxi", -4.0, 4.0, 0.1 );

variable photemis_inf = @_model_info ;
set_struct_fields( photemis_inf, "photemis", "rlogxi", -4.0, 4.0, 0.1 );


% Use eval_fun2() to evaluate each model.  This means that the
% autoname_outfile feature will not work because the
% Isis_Active_Function_Id is not defined (or is always 0).  Hence, we
% will use the unwrapped models and set the output filename via the
% env.
%

define run_models( info )
{
    variable g = struct{ bin_lo, bin_hi, value };
    (g.bin_lo, g.bin_hi) = linear_grid( 1.0, 40.0, 8192 );

    variable sfun  = info.mname;
    variable pname = info.pname;
    variable pgrid = [ info.min : info.max+info.step : info.step ] ;
    variable n = length( pgrid ); 

    variable t = get_fit_fun ;   % to save the current model

    fit_fun( "$sfun(1001)"$ );
    set_par( "$sfun(1001).write_outfile"$, 1 );

    variable fpar = get_par( "*" );
    variable pidx  = where( array_struct_field( get_params , "name" ) == "$sfun(1001).$pname"$)[0];

    fit_fun( t );  % restore the saved model

    variable i, fref = fitfun_handle( sfun );

    variable r = struct{ bin_lo, bin_hi, value };
    r.bin_lo   = @g.bin_lo ;
    r.bin_hi   = @g.bin_hi ;
    r.value    = Array_Type[ n ] ; 

    for ( i=1; i<=n; i++ )
    {
	warmabs_set_outfile( sprintf( "/tmp/%s_%0.4d.fits", sfun, 1000+i ) );
	fpar[ pidx ] = pgrid[ i-1 ] ;
	message( "Running  $sfun vs $pname ... $i"$ );
	() = printf("debug: pgrid[%d]=%8.2f\n", i-1, fpar[pidx] );
	r.value[i-1] = eval_fun2( fref, g.bin_lo, g.bin_hi, fpar );
	title( "$i"$ ); ylog; limits; hplot( r.bin_lo, r.bin_hi, r.value[i-1] );
    }
    warmabs_unset_outfile;

    return( r ) ; 
}

% for convenience ... dump par files as well:
%
define mk_pfiles( info )
{
    variable sfun  = info.mname;
    variable pname = info.pname;
    variable pgrid = [ info.min : info.max+info.step : info.step ] ;
    variable n = length( pgrid ); 

    variable t = get_fit_fun ;   % to save the current model

    fit_fun( "$sfun(1001)"$ );
    set_par( "$sfun(1001).write_outfile"$, 1 );

    variable fpar = get_par( "*" );
    variable pidx  = where( array_struct_field( get_params , "name" ) == "$sfun(1001).$pname"$)[0];

    variable i;

    for ( i=1; i<=n; i++ )
    {
	variable pfile = sprintf( "/tmp/%s_%0.4d.par", sfun, 1000+i );
	fpar[ pidx ] = pgrid[ i-1 ] ;
	fit_fun( "$sfun(1)"$ );
	set_par( "*", fpar );
	save_par( pfile );
    }

    fit_fun( t );  % restore the saved model
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#iffalse

% obsolete function, since transition was found to be degenerate:
% see xstar_collate_trans2()

define xstar_collate_trans( t )
{
    % given Struct_Type[] t,
    % find min and max "transition" values and create commensurate
    % index arrays  for each t[i].

    variable i, n = length( t );

    variable tmax = 0; 
    for( i=0; i<n; i++) tmax = max( [tmax, t[i].transition ] ) ;

    variable tf = Array_Type[ n ] ;
    for( i=0; i<n; i++ )
    {
	tf[i] = Integer_Type[ tmax + 1 ];
	tf[i][ t[i].transition ] = 1 ; 
    }

    return( tf ) ; 
}
#endif
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

define xstar_get_max_trans( t )
{
    variable i, n = length( t );

    variable tmax_line = 0;
    variable tmax_edge = 0 ; 

    for( i=0; i<n; i++)
    {
	tmax_line = max( [tmax_line, t[i].transition[where( t[i].type == "line" ) ] ] ) ;
	tmax_edge = max( [tmax_edge, t[i].transition[where( t[i].type == "edge/rrc" ) ] ] ) ;
    }
    return( tmax_line, tmax_edge );
 }

define xstar_add_unique_id_field( t ) % modify in-place
{
    variable i ; 
    for( i=0; i<length( t ); i++ )
    {
	t[i] = struct_combine( t[i], "uid" );
	t[i].uid = Integer_Type[ length( t[i].transition ) ];
    }
}

define xstar_collate_trans2( t )
{
    % given t = Struct_Type[],
    % find min and max "transition" values and create commensurate
    % index arrays  for each t[i].

    % to resolve degeneracies, "hash" the type="edge/rrc" by adding a
    % large number. (this is memory-inefficient).

    variable tmax, tmax_line, tmax_edge ;
    ( tmax_line, tmax_edge ) = xstar_get_max_trans( t );
    message( "tmax_line = ${tmax_line};  tmax_edge = ${tmax_edge}"$ );

    tmax = tmax_line + tmax_edge ; 

    variable i, n = length( t );
    variable tf = Array_Type[ n ] ;
    for( i=0; i<n; i++ )
    {
	t[i].uid = @t[i].transition ;
	t[i].uid[ where( t[i].type == "edge/rrc" ) ] += tmax_line ; 
	tf[i] = Integer_Type[ tmax + 1 ];
	tf[i][ t[i].uid ] = 1 ; 
    }
    return( tf ) ; 
}

define _xstar_load_tables( fnames )
{
    variable t = array_map( Struct_Type, &rd_xstar_output, fnames );
    xstar_add_unique_id_field( t );
    return( t );
}

% after reading a table, get a value from the params substructure:
% e.g., this is where the model rlogxi, column, vturb are.
% "interesting" parameters in xspec models are rlogxi, column, "vturb".
% These map to xstar output parameters, "rlogxi", "column", "vturbi", but column
% is in /cm^2 instead of log10[ /cm^2 / 1.e22].
%

define xstar_get_table_param( t, s)
{
    variable l = where( t.params.parameter == s )[0] ; 
    return( t.params.value[ l ] );
}

% collect the "interesting" params into arrays for each t[]:

define xstar_collect_params( t, s )
{
    variable r = struct_combine( ,  s ) ; 
    variable i ; 
    for( i=0; i<length( s ); i++ )
    {
	set_struct_field( r, s[i], array_map( Double_Type, &xstar_get_table_param, t, s[i] ) );
    }
    return( r );
}

% We need to collect "transposed" indices, for each transition (uid_flags[i]==1), we
% want an array which gives its index into each table (db[i]).  Many
% will have no values,  so we'll need to use a null index, such as -1.
%
% Brute force is to loop over each uid_flags[j], and where ==1, find where it
% is in db[j].transition[], and append to an array.
%
define xstar_collate_trans_pointers( t )
{
    variable Ndb    = length( t.uid_flags )  ;    % number or databases (model runs)
    variable Ntrans = length( t.uid_flags[0] ) ; % number of trans + 1
    variable p      = Array_Type[ Ntrans ] ; % pointer arrays, one per trans

    % initialize pointer arrays, to null pointer, -1;
    variable np = Integer_Type[ Ndb ] - 1 ;
    variable i, j ;

    p[ 0 ] = @np ;  % there is no transition=0; fill w/ null value.

    for( i=1; i<Ntrans; i++ ) % i is the unique transition number
    {
	p[ i ] = @np ;
	
	for ( j=0; j<Ndb; j++ )
	{
	    if ( t.uid_flags[j][i] )
	    {
		p[i][j] = where( t.db[j].uid == i )[0] ;
	    }
	}
    }
    return( p );
}

define xstar_all_uid( t )
{
    variable r = @t.uid_flags[0] ;
    variable i ; 
    for( i=1; i<length(t.uid_flags); i++ ) r = r or t.uid_flags[i] ;
    return( where( r ) );
}

% QUESTION: should column be scaled? the xstar param is confusing, being not 
% in units of 1.e22 like every other model, but log10 of that.

define xstar_load_tables( fnames )
{
    variable r   = struct{ db, par, uid_flags, uid_map, uids } ; 
    r.db         = _xstar_load_tables( fnames ) ;
    r.par        = xstar_collect_params( r.db, ["rlogxi", "column", "vturbi"] );
    r.par.column = log10( r.par.column ) - 22.0 ;
    r.uid_flags  = xstar_collate_trans2( r.db );
    r.uid_map    = xstar_collate_trans_pointers( r ) ;
    r.uids       = xstar_all_uid( r );
    return( r );
}


% given the structure above, an id, and a field, collect the values across tables: 
%
define xstar_collect_value( t, id, field )
{
    variable a = t.uid_map[id] ;
    variable i ;
    variable r = Double_Type[ length( a ) ] ; 
    for( i=0; i<length( a ); i++ )
    {
	if ( a[i] > 0 )
	r[i] = get_struct_field( t.db[i], field )[ a[i] ] ; 
    }
    return( r );
}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% CHECK ID UNIQUENESS:
%
% In each table, we want to know that the actual transitions for each
% transition index are identical.  This means we need to loop over
% every transition in every pair of tables.  Identical means that they
% have identical element, ion, lower_level, and upper_level fields.
% This has been encoded into the transition_name string (by us, not by
% Tim).  Well, from experiment, that's not enough.  Also need g_lo,
% g_up (and/or maybe f_ij). 

define xstar_diff_id( id, t1, t2 )
{
    variable k1 = where( t1.uid == id ) ; 
    variable k2 = where( t2.uid == id ) ; 

    if (length( k1 ) > 1) message( "Identical transitions: t1: $id"$ );
    if (length( k2 ) > 1) message( "Identical transitions: t2: $id"$ );

    variable s1 = struct_filter( t1, k1[0]; copy ) ; 
    variable s2 = struct_filter( t2, k2[0]; copy ) ;

    % returns 0 if identical:
    return( ( 0 != strcmp(s1.transition_name, s2.transition_name ) )
         or (s1.g_lo != s2.g_lo )
         or (s1.g_up != s2.g_up ) );
}

define xstar_check_trans( tbl, tid )
{
    % tbl: Struct array of xstar data
    % tid: transition id arrays
    %   tid[n] = 1 if tbl[i].uid[] has transition==n

    % Form a unique list of transition indices, then compare each pair
    % of tables which contain that transtion.  

    variable ntbl = length( tbl );   % same as length(tid);
    variable i, utrans = tid[0] * 0 ;
    for( i=0; i<length( tbl ); i++ )  utrans = utrans or tid[i] ;

    variable k = where( utrans );
    variable n_unique = length( k );

    message( "Checking uniqueness of ${n_unique} transitions in ${ntbl} model runs..."$);

    % Loop over each k, and if transition k[i] occurs in any pair of
    % tbl[i], tbl[j], compare the transitions.  Print any that differ.
    
    % (This is slow; Can any part of this be vectorized? or done w/ array_map?)

    variable n_hits = 0 ; 

    for( i=0; i < n_unique; i++ )
    {
	!if ( i mod (n_unique / 80) ) () = printf(".");
	() = fflush(stdout);

	% Each table which contains k[i] can be found from tid:
	%
	variable has_k = Integer_Type[ ntbl ];
	variable j; 
	for( j=0; j<ntbl; j++ )
	{
	    has_k[j] = tid[j][ k[i] ] ; 
	}
	variable nk = where( has_k );
	if ( length( nk ) > 1 )
	{
	    variable j1 = nk[0] ; 

	    % Compare the first to each of the next.  If this passes,
	    % then they are all identical, which is a sufficient test.
	    % If one fails, then more comparisons will be needed (and
	    % are not done here) to find out which ones agree and
	    % which don't.
	    
	    for( j=1; j<length(nk); j++ )
	    {
		variable m = xstar_diff_id( k[i], tbl[j1], tbl[ nk[j] ] );
		n_hits += m ; 
		if ( m )
		{
		    () = printf("%% Diff found for: transition=%d in tbls %d vs %d\n", k[i],j1, nk[j] ); 
		}
	    }
	}
    }
    () = printf( "\n%d differences found.\n", n_hits );
}


#stop 

.load packages/wadb/examples/warmabs_vs_xi_test


%%% to create the run of models:

variable swa, sph ; 
time; 
tic; swa =  run_models( warmabs_inf ) ;  toc; % about 21 sec each
time;
tic; sph = run_models( photemis_inf ); toc; 
time;

f = glob( "/tmp/warmabs_10*.fits" ); % NOTE: these are local to notpirx:/tmp
f = f[ array_sort( f ) ] ; 
t = xstar_load_tables( f );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% test example of collecting a feature vs parameter:

k = 50 ; 
l = xstar_strong(10, t.db[k]);
xstar_page_group( t.db[k],  l );

% manually pick out Ne VII 13.83; uid should have length [1]:
uid = t.db[k].uid[ where( t.db[k].transition == 10453 ) ];

y = xstar_collect_value( t, uid[0], "ew" );
pointstyle(24);
plot( t.par.rlogxi, y );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% ti = xstar_collate_trans( t );
% xstar_check_trans( t, ti );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% after making unique transition:

% ti = xstar_collate_trans2( t.t );
xstar_check_trans( t.db, t.uid_flags );   % all unique.



f = glob( "/tmp/photemis_10*.fits" );
f = f[ array_sort( f ) ] ; 
t = xstar_load_tables( f );

% ti = xstar_collate_trans( t );

%ti = xstar_collate_trans2( t.t );
xstar_check_trans( t.db, t.uid_flags );

% ad hoc hack to change one entry to see if found as different for
% same transition.
% Have to do is take one transition (which is likely to occur
% in more than one table) and change the transition_name by a
% character.  

% 
% transition 12

i = 0 ;
j = 445 ; 

% matches i = 1, j = 502 ; 

save_tname = t[i].transition_name[j] ;
save_tname; 
t[i].transition_name[j] = "x"+ save_tname;
xstar_check_trans( t, ti );
t[i].transition_name[j] = save_tname;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% what is needed next:  for any transition n, want array of indices to 
%  tables, i.e.
%   y[n][i] = where( n == t[i].uid) ; 
%  (n = 1...max(transition);  i = 0..(# of tables-1))
% so can collect/plot  vs i for any n of interest
%  (but have to handle missing data)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% for old way:
% MANY identical transition values  for different features.
% E.g.
s = struct_filter( t[7], where( t[7].uid==1772); copy);
warmabs_page_group( s, [0,1]);

OR:

Identical transitions: t2: 30287
% Diff found for: transition=30287 in tbls 11 vs 14

n=30287; i=11; warmabs_page_group( t[i], where(t[i].uid==n));
#      id      ion   lambda    A[s^-1]          f  gl  gu      tau_0       W(A) L[10^38 cgs]       type label
   30287   S  XIII    5.140  8.720e+12  2.073e-02   5   3  2.349e-10  5.481e-10    0.000e+00       line 2s1.2p1.3P_2 - 1s1.2s1.2p2.3D_1

n=30287; i=14; warmabs_page_group( t[i], where(t[i].uid==n));
   30287  Ni  XXII    6.500  0.000e+00  0.000e+00   4   0  1.629e-06  0.000e+00    0.000e+00   edge/rrc   2p3.4S_3/2 -     2p2.3P_1


