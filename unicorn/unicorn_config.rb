worker_processes 2
preload_app true
pid './unicorn.pid'
listen 8080

# call WebApp#initialize before access
after_fork { |_, _| WebApp.prototype }
