/*
###############################################################################
# Copyright (c) 2019, PulseRain Technology LLC 
#
# This program is distributed under a dual license: an open source license, 
# and a commercial license. 
# 
# The open source license under which this program is distributed is the 
# GNU Public License version 3 (GPLv3).
#
# And for those who want to use this program in ways that are incompatible
# with the GPLv3, PulseRain Technology LLC offers commercial license instead.
# Please contact PulseRain Technology LLC (www.pulserain.com) for more detail.
#
###############################################################################
*/


package file_compare_pkg;
            
            // file compare parameters
            typedef struct {
                string file_name;
                int num_of_column;
                int num_of_column_to_display;
                int num_of_lines;
                int base;
                int lines_to_skip;
                int init_num_of_inputs_to_ignore;
                bit verbose;
                bit pause_on_mismatch;
                bit wildcard_compare;
                bit carriage_return;
            } file_cmp_param_s;
            
            //=====================================================================
            // class        
            
                class file_compare_c;
                    
                    string file_name;
                    int file_input, c;
                    int num_of_column;
                    int num_of_column_to_display;
                    int sign, accu, base;
                    int column_index;
                    int line_index;
                    int num_of_lines;
                    int lines_to_skip;
                    int init_num_of_inputs_to_ignore;
                    int input_count;
                    
                    bit verbose;
                    bit pause_on_mismatch;
                    bit wildcard_compare;
                    bit carriage_return;
                    bit pass1_fail0;
                    
                    
                    virtual function int is_valid_number_char (input integer c, input integer base);
                        if (c inside {["0": "9"], "+", "-"}) begin
                            return 1;
                        end else if ((base > 10) && (c inside {["a": "f"], ["A": "F"]})) begin
                            return 1;
                        end
                        
                        return 0;
                        
                    endfunction
                    
                    
                    virtual function void reset();
                        
                        sign = 1;
                        line_index = 0;
                        column_index = 0;
                        pass1_fail0 = 1;
                        input_count = 0;
                        
                        c = -1;
                        if (file_input) begin
                            void'($rewind(file_input));
                        end
                    endfunction : reset
                    
                    
                    function new (file_cmp_param_s file_param);
                        this.base = file_param.base;
                        this.num_of_column = file_param.num_of_column;
                        this.num_of_column_to_display = file_param.num_of_column_to_display;
                        this.num_of_lines = file_param.num_of_lines;
                        this.lines_to_skip = file_param.lines_to_skip;
                        this.file_name = file_param.file_name;
                        this.pause_on_mismatch = file_param.pause_on_mismatch;
                        this.verbose = file_param.verbose;
                        this.init_num_of_inputs_to_ignore = file_param.init_num_of_inputs_to_ignore;
                        this.wildcard_compare = file_param.wildcard_compare;
                        this.carriage_return = file_param.carriage_return;
                        
                        file_input = 0;
                        
                        reset();
                        file_input = $fopen(file_name, "r"); 
                         
                        if (!file_input) begin
                             $display ("can't open %s", file_name);  
                             $finish();
                        end
                        
                    endfunction
                    
                    virtual function bit run (bit enable_in, integer data_to_cmp[]);
                                    if (enable_in) begin
                                        ++input_count; 
                                    end
                            
                            if ((line_index < lines_to_skip) || ((enable_in) && (input_count > init_num_of_inputs_to_ignore)))  begin   : if_enable_in_proc
                                    
                            
                                 if (line_index == 0) begin
                                        c = $fgetc(file_input);
                                 end
                                 
                                 while ((!$feof(file_input)) && (c != -1)) begin : while_loop_proc
                                 
                                     // remove the blank
                                     while (!is_valid_number_char(c, base))  begin : skip_blank_proc
                                         
                                         c = $fgetc(file_input);   
                                         
                                         if ($feof(file_input)) begin
                                             c = -1;
                                             break;
                                         end
                                         
                                     end : skip_blank_proc
                    
                                     if (c != -1) begin : if_c_is_valid
                                         
                                         // get a whole number
                                         sign = 1;
                                         accu = 0;
                                         
                                         do begin
                                             
                                             if (c == "-") begin
                                                sign = -1;
                                             end else if (c == "+") begin
                                                 sign = 1;
                                             end else if ((c >= "0") && (c <= "9")) begin
                                                 accu = accu * base + c - "0";  
                                             end else if ((c >= "A") && (c <= "F")) begin  
                                                 accu = accu * base + c - "A" + 10;
                                             end else begin
                                                 accu = accu * base + c - "a" + 10;
                                             end
                                             
                                             c = $fgetc(file_input);
                                             
                                         end while (is_valid_number_char(c, base));
                                        
                                         accu *= sign;
                                         if (line_index >= lines_to_skip) begin : if_no_need_to_skip_proc
                                            if (((data_to_cmp[column_index] !== accu) && (!wildcard_compare)) || 
                                                ((data_to_cmp[column_index] !=? accu) && (wildcard_compare))) begin : if_mismatch_proc
                                               $timeformat(-9, 3, "ns", 5);                                                
                                               if (base == 16) begin
                                                    $display ("!!! Time %t, File %s Mismatch at line %d, column %d, expecting %x, actual %x", 
                                                        $realtime(), file_name, line_index + 1, column_index + 1, accu, data_to_cmp[column_index]);
                                               end else begin
                                                   $display ("!!! Time %t, File %s Mismatch at line %d, column %d, expecting %d, actual %d", 
                                                        $realtime(), file_name, line_index + 1, column_index + 1, accu, data_to_cmp[column_index]);
                                               end
                                               
                                               pass1_fail0 = 0;
                                               
                                               if (pause_on_mismatch) begin
                                                   $stop();
                                               end  
                                               
                                            end else if ((verbose) && ((column_index + 1) == num_of_column)) begin : else_verbose_proc
                                                
                                                 $write ("%s, Match Line %d\t", file_name, line_index + 1);
                                                    
                                                 for (int i = 0; i < num_of_column_to_display; ++i) begin : for_print
                                                            if (base == 16) begin
                                                                $write ("%x\t", data_to_cmp[i]);
                                                            end else begin
                                                                $write ("%d\t", data_to_cmp[i]);
                                                            end
                                                 end : for_print
                                                 
                                                 if (carriage_return) begin
                                                    $write ("\n");
                                                 end
                                            
                                            end : else_verbose_proc
                                         end : if_no_need_to_skip_proc
                                         
                                         ++column_index;
                                         
                                         if (column_index == num_of_column) begin
                                             ++line_index;
                                             column_index = 0;
                                             
                                                        
                                             // remove the blank for next line
                                             do begin : skip_blank_for_next_iteration_proc
                                                     c = $fgetc(file_input);        
                                             end : skip_blank_for_next_iteration_proc
                                             while (!(is_valid_number_char(c, base)|| (c == -1) || $feof(file_input)));
                                             
                                             if ((line_index >= num_of_lines) && (num_of_lines)) begin
                                                    
                                                    if ((verbose) && (line_index == num_of_lines)) begin
                                                        $display ("%s has reached %d lines", file_name, num_of_lines);
                                                end
                                                
                                                    return 1; 
                                             end else if ((c == -1) || $feof(file_input)) begin
                                                break;
                                             end else begin
                                                return 0;
                                             end
                                         end
                                      end : if_c_is_valid
                                 end  : while_loop_proc

                                 if (verbose) begin
                                        $display ("=======> Time %t, %s has reached end of file, total %d lines", $realtime(), file_name, line_index);
                                 end
                                 
                                 if (line_index < num_of_lines) begin
                                    $display ("Time %t, File input %s, expecting %d lines, actual %d lines", 
                                        $realtime(), file_name, num_of_lines, line_index);
                                    $stop();
                                    
                                 end 
                                 
                                 return 1;
                            
                            end : if_enable_in_proc      
                            
                            return 0;

                             
                    endfunction : run
                    
                endclass : file_compare_c

endpackage : file_compare_pkg
