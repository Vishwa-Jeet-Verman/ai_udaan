const errorHandler = (err, req, res, next) => {
    const isProd = process.env.NODE_ENV === 'production';

    if (!isProd) {
        console.error('Error:', err.message);
        console.error(err.stack);
    } else {
        console.error(`[${new Date().toISOString()}] ${err.message}`);
    }

    // Multer file size error
    if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ error: 'File too large. Maximum size is 5MB.' });
    }

    // Multer unexpected field error
    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
        return res.status(400).json({ error: 'Unexpected file field.' });
    }

    const statusCode = err.statusCode || 500;
    const message = err.statusCode ? err.message : 'Internal server error';

    res.status(statusCode).json({ error: message });
};

module.exports = errorHandler;
