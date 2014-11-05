
static variable _help_rd_xstar_output = 
["\n", 
 "  USAGE: db = rd_xstar_output( filename )\n",
 "\n",
 "  Reads the output table from an XSTAR model\n", 
 "  Returns a structure, containing fields sorted by ascending wavelength\n",
 "    transition  : (int) an index for the transition\n",
 "    type        : (string) \"line\" or \"edge/rrc\"\n",
 "    ion         : (string) describing ion, e.g. \"si_iv\"\n",
 "    wavelength  : (double) transition wavelength in Angs\n",
 "    tau0        : (float) optical depth of the transition (??)\n",
 "    tau0grid    : (float) optical depth of the transition (??)\n",
 "    ew          : (float) equivalent width of a line transition,\n",
 "                  has a negative value in the case of emission\n",
 "    luminosity  : (float) luminosity of a line transition\n",
 "    lower_level : (string) lower level of transition\n",
 "    upper_level : (string) upper level of transition\n",
 "    a_ij        : (float) A_ij rate coefficient\n",
 "    f_ij        : (float) f_ij rate coefficient\n",
 "    g_lo        : (float) g value for lower level of transition\n",
 "    g_up        : (float) g value for upper level of transition\n",
 "    ind_lo      : (int) index for transition lower level,\n",
 "    ind_up      : (int) index for transition upper level,\n",
 "    ind_ion     : (int) index for ion\n",
 "\n",
 "  fields added to the basic output:\n",
 "    model_name  : (string) \"warmabs\" or \"photemis\", etc...\n",
 "    Z           : (int) atomic number; e.g., Ne = 10\n",
 "    q           : (int) ion state (arabic; e.g., 9 for IX)\n",
 "    params      : sub-structure holding model parameters\n",
 "    transition_name : (string) description of other fields \n",
 "                     \"<Element> <ion> <upper_level> <lower_level> <type>\"\n",
 "    filename    : (string) name of file(s) the database was read from\n",
 "\n",
 "  merged databases only (see xstar_merge)\n",
 "    origin_file     : (int) index of s.filename from which transition was read\n"];



%define rd_xstar_output_help()
%{
%    () = array_map( Integer_Type, &fprintf, stdout, _help_rd_xstar_output );
%}


