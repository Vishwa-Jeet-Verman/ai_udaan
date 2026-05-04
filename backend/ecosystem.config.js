module.exports = {
    apps: [
        {
            name: 'ngtech-lms-backend',
            script: 'server.js',
            instances: 'max',
            exec_mode: 'cluster',
            env: {
                NODE_ENV: 'production',
                PORT: 9000,
            },
            env_production: {
                NODE_ENV: 'production',
                PORT: 9000,
            },
            error_file: './logs/err.log',
            out_file: './logs/out.log',
            merge_logs: true,
            log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
        },
    ],
};
