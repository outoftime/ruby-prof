# encoding: utf-8

require 'json'

module RubyProf

  #
  # Generates a JSON dump of the Ruby stack
  #
  # result = RubyProf.profile do
  #   [code to profile]
  # end
  #
  # printer = JSONStackPrinter.new(result)
  # printer.print STDOUT
  #
  class JSONStackPrinter < AbstractPrinter

    # Encode data from all threads and then print
    def print(output = STDOUT, options = {})
      data = { :label => '(root)', :children => [], :percentage => 100 }
      @total_time = @result.threads.inject(0) { |val, thread| val += thread.total_time }.to_f
      @result.threads.each do |thread|
        record_thread(thread, data[:children])
      end
      output.puts data.to_json
    end

    private

    # Record a single thread
    def record_thread(thread, arr)
      thread.methods.each do |method|
        next unless method.root?
        method.call_infos.each do |call_info|
          next unless call_info.root?
          record_call_info call_info, arr
        end
      end
    end

    def record_call_info(call_info, arr)
      full_name = call_info.target.full_name
      local_data = arr.detect { |c| c[:label] == full_name }
      unless local_data
        local_data = { :label => full_name, :percentage => 0 }
        arr << local_data
      end
      local_data[:percentage] += (call_info.total_time / @total_time) * 100 # eek
      # record children
      unless call_info.children.empty?
        children_arr = (local_data[:children] ||= [])
        call_info.children.each do |child|
          record_call_info child, children_arr
        end
      end
    end

  end

end
