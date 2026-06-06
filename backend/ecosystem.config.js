module.exports = {
    apps: [
        {
            name: 'ai-udaan-backend',
            script: 'server.js',

            // Cluster mode: one process per CPU core for max throughput
            instances: 'max',
            exec_mode: 'cluster',

            // Environment
            env_production: {
                NODE_ENV: 'production',
                PORT: 9000,
                BASE_URL: 'https://backend.aiudaanbootcamp.com',
            },

            // Auto-restart on crash
            autorestart: true,
            watch: false,           // Never watch files in production
            max_restarts: 10,       // Max restarts before PM2 gives up
            restart_delay: 4000,    // Wait 4s between restarts
            min_uptime: '10s',      // Must stay alive 10s to count as successful start

            // Memory limit — restart if a worker leaks beyond 512 MB
            max_memory_restart: '512M',

            // Logs
            error_file: './logs/err.log',
            out_file: './logs/out.log',
            merge_logs: true,
            log_date_format: 'YYYY-MM-DD HH:mm:ss Z',

            // Zero-downtime reloads
            kill_timeout: 10000,    // Grace period (ms) before SIGKILL on reload
            listen_timeout: 8000,   // How long to wait for app to be ready
        },
    ],
};
