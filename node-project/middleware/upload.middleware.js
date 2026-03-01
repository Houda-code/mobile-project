const fs = require('fs');
const path = require('path');
const multer = require('multer');

const uploadDir = path.join(__dirname, '..', 'uploads', 'users');
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadDir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase();
    const safeExt = ext || '.jpg';
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}${safeExt}`;
    cb(null, unique);
  },
});

const fileFilter = (_req, file, cb) => {
  const mimeOk = file.mimetype && file.mimetype.startsWith('image/');
  if (mimeOk) return cb(null, true);

  const ext = path.extname(file.originalname || '').toLowerCase();
  const allowed = new Set(['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif']);
  if (allowed.has(ext)) {
    return cb(null, true);
  }

  return cb(new Error('Only image files are allowed'));
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 },
});

module.exports = upload;
