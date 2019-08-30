new_project \
         -name {creative} \
         -location {C:\GitHub\Rattlesnake\build\par\Microchip\creative\designer\creative\creative_fp} \
         -mode {chain} \
         -connect_programmers {FALSE}
add_actel_device \
         -device {M2GL025} \
         -name {M2GL025}
enable_device \
         -name {M2GL025} \
         -enable {TRUE}
save_project
close_project
