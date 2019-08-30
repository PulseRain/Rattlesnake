open_project -project {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative_fp\creative.pro}\
         -connect_programmers {FALSE}
if { [catch {load_programming_data \
    -name {M2GL025} \
    -fpga {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.map} \
    -header {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.hdr} \
    -spm {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.spm} \
    -dca {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative.dca} } return_val] } {
    save_project
    close_project
    exit }
if { [catch {export_single_ppd \
    -name {M2GL025} \
    -file {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\export/tempExport\creative.ppd}} return_val ] } {
    save_project
    close_project
    exit}

set_programming_file -name {M2GL025} -no_file
save_project
close_project
