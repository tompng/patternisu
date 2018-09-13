# puma -C puma_config.rb
workers 2
threads 16, 16
preload_app!

$worker_id = 0
on_worker_fork { $worker_id += 1 }
# call WebApp#initialize before access
on_worker_boot { WebApp.prototype }
