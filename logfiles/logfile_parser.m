

files = cellstr(ls('failsafe.log'));
error_idx = cell(length(files));

 for f = 1:length(files)
     filename = files{f};
     [EventType, Code, Time] = import_log(filename);
% % 
% %     code_idx = find(strcmp(EventType, 'Port Input') == 1 );
% %     Code = Code(code_idx);
% %     Time = Time(code_idx);
% %     output = cell(length(Code), 1);
% %     start_time = Time(1);
% %     j = 1;
% %     %FileID = fopen('text_signals.txt', 'w');
% % 
% %     for i = 1:length(Code)
% %         if (Time(i) - start_time) > 300
% %            start_time = Time(i); 
% %            j = j + 1;
% %         end
% %         new_char = char(Code(i));
% %         output{j} =  strcat(output{j}, new_char);
% %     end
% %     output = output(~cellfun(@isempty, output));
% %     sizes = cellfun(@numel, output);
% %     error_idx{f} = find(sizes(1:end) ~= 4);
% %     error_idx{f}(error_idx{f} == 1) = []; 
% %     error_idx{f}(error_idx{f} == length(output)) = [];
  end
% % error_idx = error_idx(~cellfun(@isempty, error_idx));
% % error_amounts = cellfun(@numel, error_idx);
% % %fprintf('%d %d %s\n',error_idx, Time(error_idx),output{error_idx});
