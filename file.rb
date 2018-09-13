last_access_time = last_modified_time = Time.now
p File.mtime __FILE__
File.utime last_access_time, last_modified_time, __FILE__
p File.mtime __FILE__
