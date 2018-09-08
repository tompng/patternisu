# puma -C puma_config.rb
workers 2
threads 16, 16
preload_app!

# call WebApp#initialize before access
on_worker_boot { WebApp.prototype }
