/**
 * Storage Service — Local Disk
 * ─────────────────────────────────────────────────────────────────────────────
 * Stores uploaded lesson files on the local filesystem under /uploads/.
 * Files are served statically by Express.
 * When you're ready to move to S3/R2/Cloudflare, only this file needs to change.
 */

const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const UPLOAD_DIR = path.join(__dirname, '../uploads');

// Ensure the uploads folder exists on startup
if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

// ─── Multer — Disk Storage ───────────────────────────────────────────────────
const diskStorage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, UPLOAD_DIR),
    filename: (_req, file, cb) => {
        const ext = path.extname(file.originalname);
        const unique = `${Date.now()}-${crypto.randomBytes(6).toString('hex')}`;
        cb(null, `${unique}${ext}`);
    },
});

const upload = multer({
    storage: diskStorage,
    limits: { fileSize: (parseInt(process.env.MAX_FILE_SIZE_MB) || 100) * 1024 * 1024 },
    fileFilter: (_req, file, cb) => {
        const allowed = [
            'video/mp4', 'video/webm', 'video/avi', 'video/quicktime',
            'application/pdf',
        ];
        if (allowed.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type. Only MP4, WebM, AVI, MOV videos and PDFs allowed.'));
        }
    },
});

// ─── Save a file from buffer (for direct buffer uploads if needed) ───────────
const saveBuffer = async (file) => {
    const ext = path.extname(file.originalname);
    const unique = `${Date.now()}-${crypto.randomBytes(6).toString('hex')}`;
    const filename = `${unique}${ext}`;
    const filepath = path.join(UPLOAD_DIR, filename);

    return new Promise((resolve, reject) => {
        fs.writeFile(filepath, file.buffer, (err) => {
            if (err) return reject(err);
            resolve({ filename, filepath });
        });
    });
};

// ─── Delete a file by its stored filename ───────────────────────────────────
const deleteFile = async (filename) => {
    if (!filename) return;
    const filepath = path.join(UPLOAD_DIR, path.basename(filename));
    try {
        if (fs.existsSync(filepath)) fs.unlinkSync(filepath);
    } catch (err) {
        console.error('⚠️  Could not delete file:', filename, err.message);
    }
};

// ─── Build the public URL served by Express static ───────────────────────────
const getFileUrl = (req, filename) => {
    if (!filename) return null;
    const host = `${req.protocol}://${req.get('host')}`;
    return `${host}/uploads/${path.basename(filename)}`;
};

module.exports = {
    upload,       // multer middleware
    saveBuffer,   // save a buffer directly
    deleteFile,   // delete by filename
    getFileUrl,   // build a full URL from req + filename
};
