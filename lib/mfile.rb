# MFile - Useful helper functions
require 'fileutils'
require 'securerandom'

# Make a temporary directory in /temp, and delete its contents after you're done
def make_temp_dir
  curr_dir = Dir.pwd
  # FileUtils.mkdir 'temp' unless File.exist? 'temp'
  rand_dir = 'temp/' + SecureRandom.hex(16)  
  FileUtils.mkdir rand_dir
  yield rand_dir
  FileUtils.rm_r rand_dir
end

# Change to this directory, and return after the block
def chdir_return(new_dir)
  curr_dir = Dir.pwd
  Dir.chdir new_dir
  yield
  Dir.chdir curr_dir
end

if __FILE__ == $0
  make_temp_dir do |tempdir|
    puts tempdir
  end
end