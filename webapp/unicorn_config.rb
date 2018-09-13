# unicorn -c unicorn_config.rb
worker_processes 2
preload_app true
pid './unicorn.pid'
listen 8080

$worker_id = 0
before_fork { |_, _| $worker_id += 1 }
# call WebApp#initialize before access
after_fork { |_, _| WebApp.prototype }
