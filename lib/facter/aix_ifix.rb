#
#  FACT(S):     aix_ifix
#
#  PURPOSE:     This custom fact returns a hash of elements based on the 
#		installation and status of ifixes via 'emgr'.  It goes past
#		the CLI since that's tough to parse and uses internal DB
#		files which may change at any time.  Kludge alert!
#
#  RETURNS:     (hash)
#
#  AUTHOR:      Chris Petersen, Crystallized Software
#
#  DATE:        August 9, 2022
#
#  NOTES:       Myriad names and acronyms are trademarked or copyrighted by IBM
#               including but not limited to IBM, PowerHA, AIX, RSCT (Reliable,
#               Scalable Cluster Technology), and CAA (Cluster-Aware AIX).  All
#               rights to such names and acronyms belong with their owner.
#
#-------------------------------------------------------------------------------
#
#  LAST MOD:    (never)
#
#  MODIFICATION HISTORY:
#
#	(none)
#
#-------------------------------------------------------------------------------
#
Facter.add(:aix_ifix) do
    #  This only applies to the AIX operating system
    confine :osfamily => 'AIX'

    #  Capture the installation status and version if it's there
    setcode do
        #  Define the hash we'll fill and return
        l_aixIFIX                 = {}
        l_aixIFIX['present']      = false
        l_aixIFIX['hash']         = {}

        if (File.exists? '/usr/emgrdata/DBS/efix.db')

            if (!File.zero? '/usr/emgrdata/DBS/efix.db')

                #  Read and minimally parse the efix.db file (which is not a binary database format)
                l_lines = Facter::Util::Resolution.exec('/bin/cat /usr/emgrdata/DBS/efix.db 2>/dev/null')

                #  Loop over the lines that were returned
                l_lines && l_lines.split("\n").each do |l_oneLine|
                    #  Skip comments and blanks
                    l_oneLine = l_oneLine.strip()
                    next if l_oneLine =~ /^#/ or l_oneLine =~ /^$/

                    #  Split on vertical bars since that seems to work and give clean data
                    l_list = l_oneLine.split('|')
                    begin
                        l_aixIFIX['present']                        = true
                        l_aixIFIX['hash'][l_list[0]]                = {}
                        l_aixIFIX['hash'][l_list[0]]['date_time']   = l_list[20]
                        l_aixIFIX['hash'][l_list[0]]['description'] = l_list[2]
                        l_aixIFIX['hash'][l_list[0]]['packages']    = {}
                    end
                end
            end

            if (!File.zero? '/usr/emgrdata/DBS/pkglck.db')

                #  Read and minimally parse the pkglck.db file (which is not a binary database format)
                l_lines = Facter::Util::Resolution.exec('/bin/cat /usr/emgrdata/DBS/pkglck.db 2>/dev/null')

                #  Loop over the lines that were returned
                l_lines && l_lines.split("\n").each do |l_oneLine|
                    #  Skip comments and blanks
                    l_oneLine = l_oneLine.strip()
                    next if l_oneLine =~ /^#/ or l_oneLine =~ /^$/

                    #  Split on vertical bars since that seems to work and give clean data
                    l_list = l_oneLine.split('|')
                    begin
                        l_aixIFIX['hash'][l_list[0]]['packages'][l_list[6]] = l_list[14]
                    end
                end
            end

        end

        #  Implicitly return the contents of the hash
        l_aixIFIX
    end
end
