job_type :execute_order, 'EXECUTE_WHENEVER {"agent":"data_injection_agent", "order":":task", "params":":params"}'
# Define here your agent scheduled callbacks

# Examples:

# every 2.hours do
#   execute_order "66"
# end

# every 1.day, :at => '4:30 am' do
#   execute_order "refresh", :params => "parameters"
# end

# You MUST use the command 'execute_order'

# Learn more about whenever: http://github.com/javan/whenever

job_type :execute_order, 'EXECUTE_WHENEVER {"agent":"ragent_basic_tests_agent", "order":":task", "params":":params"}'
# Define here your agent scheduled callbacks

# Examples:

# every 2.hours do
#   execute_order "66"
# end

# every 1.day, :at => '4:30 am' do
#   execute_order "refresh", :params => "parameters"
# end

# You MUST use the command 'execute_order'

# Learn more about whenever: http://github.com/javan/whenever

every 2.hours do
  execute_order "send message"
end

every 2.hours do
  execute_order "inject mesage"
end

every 2.hours do
  execute_order "inject track"
end

every 2.hours do
  execute_order "send_protogen_message"
end
